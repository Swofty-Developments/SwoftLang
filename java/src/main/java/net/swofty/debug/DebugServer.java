package net.swofty.debug;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;

import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;

/**
 * The live debug tracer (VS Code extension Part 3). A tiny hand-rolled
 * WebSocket server that streams execution-trace, handler enter/exit, and hot
 * reload events to any connected client (newline-free, one JSON object per WS
 * text frame). It is best-effort and lossy under load: {@link #broadcast}
 * enqueues onto a bounded ring and a single sender thread drains it — the tick
 * thread never blocks and the oldest message is dropped when the ring is full.
 *
 * <p>Emission is gated behind the volatile {@link #enabled} flag so a server
 * started without {@code --debug} pays only one volatile read + branch per
 * executed statement.
 */
public final class DebugServer {
    private DebugServer() {
    }

    /**
     * ZERO-cost gate: false unless {@code --debug} started the tracer. Every
     * trace/handler emission checks this first, so a normal server never
     * builds a JSON string or touches the queue.
     */
    public static volatile boolean enabled = false;

    private static final String WS_MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    private static final int QUEUE_CAPACITY = 8192;

    private static final ArrayBlockingQueue<String> QUEUE = new ArrayBlockingQueue<>(QUEUE_CAPACITY);
    private static final List<Client> CLIENTS = new CopyOnWriteArrayList<>();
    private static final AtomicLong SEQ = new AtomicLong();
    /** Handler currently executing on this thread (null outside handlers). */
    private static final ThreadLocal<String> HANDLER = new ThreadLocal<>();

    private static volatile boolean running;
    private static volatile ServerSocket serverSocket;
    private static volatile String scriptsDirAbs = "";
    private static Thread acceptThread;
    private static Thread senderThread;

    /**
     * Test hook: when set, every broadcast message is also handed here. Lets
     * the headless harness assert trace/handler/reload JSON without a live
     * socket. Not used by the running server.
     */
    private static volatile Consumer<String> testListener;

    // ---------------------------------------------------------------- lifecycle

    /**
     * Bind the WebSocket port and start the accept + sender threads. Sets
     * {@link #enabled}. A bind failure logs and leaves the tracer off rather
     * than crashing the server. Idempotent.
     * @param port the ws port (default 25580)
     * @param scriptsDir absolute path of the scripts directory (for hello)
     */
    public static synchronized void start(int port, String scriptsDir) {
        if (running) {
            return;
        }
        scriptsDirAbs = scriptsDir != null ? scriptsDir : "";
        try {
            serverSocket = new ServerSocket(port);
        } catch (IOException e) {
            System.err.println("[debug] could not bind debug ws port " + port + ": " + e.getMessage());
            return;
        }
        running = true;
        enabled = true;
        senderThread = new Thread(DebugServer::senderLoop, "swoft-debug-sender");
        senderThread.setDaemon(true);
        senderThread.start();
        acceptThread = new Thread(DebugServer::acceptLoop, "swoft-debug-accept");
        acceptThread.setDaemon(true);
        acceptThread.start();
        System.out.println("[debug] SwoftLang tracer listening on ws://0.0.0.0:" + port
                + " (scripts: " + scriptsDirAbs + ")");
    }

    /** Stop the server, disconnect clients, and disable emission. */
    public static synchronized void stop() {
        enabled = false;
        running = false;
        ServerSocket socket = serverSocket;
        if (socket != null) {
            try {
                socket.close();
            } catch (IOException ignored) {
            }
        }
        serverSocket = null;
        for (Client client : CLIENTS) {
            client.close();
        }
        CLIENTS.clear();
        if (senderThread != null) {
            senderThread.interrupt();
        }
        QUEUE.clear();
    }

    /** For the headless harness: capture broadcast JSON without a socket. */
    public static void setTestListener(Consumer<String> listener) {
        testListener = listener;
    }

    // ---------------------------------------------------------------- emission

    /**
     * Emit a per-statement trace. Only nodes carrying a source position
     * (every {@link AbstractAstNode}) produce a trace; the file was threaded
     * onto the node at load time. Called from the one statement choke point.
     */
    public static void trace(Statement statement) {
        if (!(statement instanceof AbstractAstNode node)) {
            return;
        }
        StringBuilder sb = new StringBuilder(160);
        sb.append("{\"type\":\"trace\",\"file\":").append(jsonString(node.getFile()));
        sb.append(",\"line\":").append(node.getLine());
        sb.append(",\"col\":").append(node.getCol());
        sb.append(",\"kind\":").append(jsonString(node.getKind()));
        sb.append(",\"handler\":").append(jsonString(HANDLER.get()));
        sb.append(",\"seq\":").append(SEQ.incrementAndGet());
        sb.append(",\"ts\":").append(System.currentTimeMillis());
        sb.append('}');
        broadcast(sb.toString());
    }

    /**
     * Emit a handler enter/exit event.
     * @param phase "enter" or "exit"
     */
    public static void handlerEvent(String phase, String name, String file, int line) {
        StringBuilder sb = new StringBuilder(120);
        sb.append("{\"type\":\"handler\",\"phase\":").append(jsonString(phase));
        sb.append(",\"file\":").append(jsonString(file));
        sb.append(",\"line\":").append(line);
        sb.append(",\"name\":").append(jsonString(name));
        sb.append('}');
        broadcast(sb.toString());
    }

    /**
     * Emit a hot-reload result.
     * @param file workspace-relative script path
     * @param ok whether the recompile succeeded
     * @param error the swoftc error text (null when ok)
     */
    public static void reload(String file, boolean ok, String error) {
        StringBuilder sb = new StringBuilder(120);
        sb.append("{\"type\":\"reload\",\"file\":").append(jsonString(file));
        sb.append(",\"ok\":").append(ok);
        if (!ok) {
            sb.append(",\"error\":").append(jsonString(error));
        }
        sb.append('}');
        broadcast(sb.toString());
    }

    /** Current handler name on this thread, or null. */
    public static String currentHandler() {
        return HANDLER.get();
    }

    /** Set the handler name for this thread (null to clear). */
    public static void setCurrentHandler(String name) {
        if (name == null) {
            HANDLER.remove();
        } else {
            HANDLER.set(name);
        }
    }

    /**
     * Non-blocking, lossy enqueue: drops the oldest message when the ring is
     * full so the calling (tick) thread never blocks. Also feeds the test
     * listener if one is set.
     */
    public static void broadcast(String json) {
        Consumer<String> listener = testListener;
        if (listener != null) {
            try {
                listener.accept(json);
            } catch (RuntimeException ignored) {
            }
        }
        if (!QUEUE.offer(json)) {
            QUEUE.poll();
            QUEUE.offer(json);
        }
    }

    // ---------------------------------------------------------------- internals

    private static void senderLoop() {
        while (running) {
            String message;
            try {
                message = QUEUE.take();
            } catch (InterruptedException e) {
                break;
            }
            for (Client client : CLIENTS) {
                if (!client.send(message)) {
                    CLIENTS.remove(client);
                    client.close();
                }
            }
        }
    }

    private static void acceptLoop() {
        while (running) {
            ServerSocket socket = serverSocket;
            if (socket == null) {
                break;
            }
            Socket connection;
            try {
                connection = socket.accept();
            } catch (IOException e) {
                if (running) {
                    continue;
                }
                break;
            }
            try {
                if (handshake(connection)) {
                    Client client = new Client(connection);
                    // Greet this client directly BEFORE it joins the broadcast
                    // list, so hello is guaranteed to be the first frame it
                    // receives (the protocol invariant — hello carries scriptsDir
                    // the client needs before it can resolve any trace). If it
                    // were added to CLIENTS first, the sender thread draining the
                    // shared queue to every client could deliver an
                    // already-queued trace/reload frame to this connection ahead
                    // of hello, and the extension would drop it as a trace for an
                    // unknown file.
                    client.send(hello());
                    CLIENTS.add(client);
                    startReader(client);
                } else {
                    connection.close();
                }
            } catch (IOException e) {
                try {
                    connection.close();
                } catch (IOException ignored) {
                }
            }
        }
    }

    /**
     * Drain a client's incoming frames (subscribe/close/ping) on its own
     * daemon thread so a closed or reconnecting client is pruned promptly.
     * The contents are ignored — the server streams by default.
     */
    private static void startReader(Client client) {
        Thread reader = new Thread(() -> {
            try {
                InputStream in = client.socket.getInputStream();
                while (running && readFrame(in) != CLOSE) {
                    // discard client frames
                }
            } catch (IOException ignored) {
            } finally {
                CLIENTS.remove(client);
                client.close();
            }
        }, "swoft-debug-reader");
        reader.setDaemon(true);
        reader.start();
    }

    private static final int CLOSE = -2;

    /**
     * Read and discard one client frame; returns {@link #CLOSE} on a close
     * frame or EOF. Client frames are masked (RFC 6455).
     */
    private static int readFrame(InputStream in) throws IOException {
        int b0 = in.read();
        if (b0 < 0) {
            return CLOSE;
        }
        int opcode = b0 & 0x0F;
        int b1 = in.read();
        if (b1 < 0) {
            return CLOSE;
        }
        boolean masked = (b1 & 0x80) != 0;
        long len = b1 & 0x7F;
        if (len == 126) {
            len = ((long) readByte(in) << 8) | readByte(in);
        } else if (len == 127) {
            len = 0;
            for (int i = 0; i < 8; i++) {
                len = (len << 8) | readByte(in);
            }
        }
        if (masked) {
            skip(in, 4);
        }
        skip(in, len);
        return opcode == 0x8 ? CLOSE : opcode;
    }

    private static int readByte(InputStream in) throws IOException {
        int b = in.read();
        if (b < 0) {
            throw new IOException("eof");
        }
        return b;
    }

    private static void skip(InputStream in, long n) throws IOException {
        for (long i = 0; i < n; i++) {
            if (in.read() < 0) {
                throw new IOException("eof");
            }
        }
    }

    /**
     * Perform the RFC 6455 opening handshake. Reads request headers up to the
     * blank line (exact — leaves the stream at the first frame), echoes the
     * accept key. Returns false when the request is not a WebSocket upgrade.
     */
    private static boolean handshake(Socket socket) throws IOException {
        InputStream in = socket.getInputStream();
        StringBuilder request = new StringBuilder();
        int prev = -1;
        int cur;
        int matched = 0;
        // read until CRLF CRLF
        while ((cur = in.read()) != -1) {
            request.append((char) cur);
            if ((prev == '\r' && cur == '\n')) {
                matched++;
                if (matched == 2) {
                    break;
                }
            } else if (cur != '\r') {
                matched = 0;
            }
            prev = cur;
            if (request.length() > 16384) {
                return false;
            }
        }
        String key = null;
        for (String line : request.toString().split("\r\n")) {
            int colon = line.indexOf(':');
            if (colon > 0 && line.substring(0, colon).trim()
                    .equalsIgnoreCase("Sec-WebSocket-Key")) {
                key = line.substring(colon + 1).trim();
                break;
            }
        }
        if (key == null) {
            return false;
        }
        String accept = base64Sha1(key + WS_MAGIC);
        String response = "HTTP/1.1 101 Switching Protocols\r\n"
                + "Upgrade: websocket\r\n"
                + "Connection: Upgrade\r\n"
                + "Sec-WebSocket-Accept: " + accept + "\r\n\r\n";
        OutputStream out = socket.getOutputStream();
        out.write(response.getBytes(StandardCharsets.US_ASCII));
        out.flush();
        return true;
    }

    private static String base64Sha1(String value) {
        try {
            MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
            byte[] digest = sha1.digest(value.getBytes(StandardCharsets.US_ASCII));
            return Base64.getEncoder().encodeToString(digest);
        } catch (Exception e) {
            throw new IllegalStateException("SHA-1 unavailable", e);
        }
    }

    private static String hello() {
        return "{\"type\":\"hello\",\"protocol\":1,\"scriptsDir\":"
                + jsonString(scriptsDirAbs) + "}";
    }

    /** JSON-encode a string value (or the literal null). */
    private static String jsonString(String value) {
        if (value == null) {
            return "null";
        }
        StringBuilder sb = new StringBuilder(value.length() + 2);
        sb.append('"');
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '"' -> sb.append("\\\"");
                case '\\' -> sb.append("\\\\");
                case '\n' -> sb.append("\\n");
                case '\r' -> sb.append("\\r");
                case '\t' -> sb.append("\\t");
                case '\b' -> sb.append("\\b");
                case '\f' -> sb.append("\\f");
                default -> {
                    if (c < 0x20) {
                        sb.append(String.format("\\u%04x", (int) c));
                    } else {
                        sb.append(c);
                    }
                }
            }
        }
        sb.append('"');
        return sb.toString();
    }

    /** One connected WebSocket client; writes are serialized per connection. */
    private static final class Client {
        private final Socket socket;
        private final OutputStream out;

        Client(Socket socket) throws IOException {
            this.socket = socket;
            this.out = socket.getOutputStream();
        }

        /** Send one text frame (unmasked, server→client). False if dead. */
        synchronized boolean send(String message) {
            try {
                byte[] payload = message.getBytes(StandardCharsets.UTF_8);
                out.write(0x81); // FIN + text opcode
                int len = payload.length;
                if (len < 126) {
                    out.write(len);
                } else if (len < 65536) {
                    out.write(126);
                    out.write((len >>> 8) & 0xFF);
                    out.write(len & 0xFF);
                } else {
                    out.write(127);
                    for (int i = 7; i >= 0; i--) {
                        out.write((int) ((long) len >>> (8 * i)) & 0xFF);
                    }
                }
                out.write(payload);
                out.flush();
                return true;
            } catch (IOException e) {
                return false;
            }
        }

        void close() {
            try {
                socket.close();
            } catch (IOException ignored) {
            }
        }
    }
}
