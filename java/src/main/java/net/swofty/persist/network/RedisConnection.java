package net.swofty.persist.network;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Minimal RESP (REdis Serialization Protocol) client — enough for the
 * coordinator role in design 1.10.0 §2: {@code SET NX PX} leases, {@code EVAL}
 * compare-and-delete, {@code INCR} generations, and {@code PUBLISH}/
 * {@code SUBSCRIBE} for the change bus.
 *
 * <p>Written by hand rather than pulling a client library in: the protocol
 * surface used here is a dozen commands, and the engine ships no other redis
 * dependency. One connection is one socket; commands are serialized on the
 * instance monitor. A subscriber uses its OWN connection (a subscribed
 * connection may not issue ordinary commands).
 *
 * <p>Reply mapping: simple string / bulk string to {@link String}, integer to
 * {@link Long}, array to {@link List}, nil to {@code null}, error to an
 * {@link IOException} (so a caller's retry path treats it like any other IO
 * failure).
 */
public final class RedisConnection implements AutoCloseable {
    private static final int CONNECT_TIMEOUT_MILLIS = 3_000;

    private final String host;
    private final int port;
    private final String password;
    private final int database;
    private final int readTimeoutMillis;

    private Socket socket;
    private OutputStream out;
    private InputStream in;

    private RedisConnection(String host, int port, String password, int database,
            int readTimeoutMillis) {
        this.host = host;
        this.port = port;
        this.password = password;
        this.database = database;
        this.readTimeoutMillis = readTimeoutMillis;
    }

    /**
     * Open a connection to {@code redis://[:password@]host[:port][/db]}.
     * A read timeout of 0 blocks forever (what a subscriber wants).
     */
    public static RedisConnection open(String uri, int readTimeoutMillis) throws IOException {
        String host = "localhost";
        int port = 6379;
        String password = null;
        int database = 0;
        try {
            URI parsed = URI.create(uri == null || uri.isBlank() ? "redis://localhost:6379" : uri);
            if (parsed.getHost() != null) {
                host = parsed.getHost();
            }
            if (parsed.getPort() > 0) {
                port = parsed.getPort();
            }
            String userInfo = parsed.getUserInfo();
            if (userInfo != null) {
                int colon = userInfo.indexOf(':');
                password = colon >= 0 ? userInfo.substring(colon + 1) : userInfo;
            }
            String path = parsed.getPath();
            if (path != null && path.length() > 1) {
                try {
                    database = Integer.parseInt(path.substring(1));
                } catch (NumberFormatException ignored) {
                    // a non-numeric path is not a database selector; keep 0
                }
            }
        } catch (IllegalArgumentException e) {
            throw new IOException("bad redis uri '" + uri + "': " + e.getMessage(), e);
        }
        RedisConnection connection =
                new RedisConnection(host, port, password, database, readTimeoutMillis);
        connection.connect();
        return connection;
    }

    private synchronized void connect() throws IOException {
        socket = new Socket();
        socket.setTcpNoDelay(true);
        socket.setKeepAlive(true);
        socket.connect(new InetSocketAddress(host, port), CONNECT_TIMEOUT_MILLIS);
        socket.setSoTimeout(readTimeoutMillis);
        out = socket.getOutputStream();
        in = socket.getInputStream();
        if (password != null && !password.isEmpty()) {
            command("AUTH", password);
        }
        if (database > 0) {
            command("SELECT", String.valueOf(database));
        }
    }

    /** Reconnect after an IO failure; the caller retries its command. */
    public synchronized void reconnect() throws IOException {
        closeQuietly();
        connect();
    }

    /** Whether the socket is currently usable. */
    public synchronized boolean isOpen() {
        return socket != null && socket.isConnected() && !socket.isClosed();
    }

    /** Send one command and read exactly one reply. */
    public synchronized Object command(String... args) throws IOException {
        write(args);
        return readReply();
    }

    /** Send a command without reading its reply (subscriber setup). */
    public synchronized void send(String... args) throws IOException {
        write(args);
    }

    private void write(String... args) throws IOException {
        if (out == null) {
            throw new IOException("redis connection is closed");
        }
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        buffer.write(('*' + String.valueOf(args.length) + "\r\n")
                .getBytes(StandardCharsets.UTF_8));
        for (String arg : args) {
            byte[] bytes = arg.getBytes(StandardCharsets.UTF_8);
            buffer.write(('$' + String.valueOf(bytes.length) + "\r\n")
                    .getBytes(StandardCharsets.UTF_8));
            buffer.write(bytes);
            buffer.write('\r');
            buffer.write('\n');
        }
        out.write(buffer.toByteArray());
        out.flush();
    }

    /** Read one reply off the socket (blocking). Public for the subscriber loop. */
    public Object readReply() throws IOException {
        int marker = in.read();
        if (marker < 0) {
            throw new IOException("redis connection closed by peer");
        }
        switch (marker) {
            case '+':
                return readLine();
            case '-':
                throw new IOException("redis error: " + readLine());
            case ':':
                return Long.parseLong(readLine());
            case '$': {
                int length = Integer.parseInt(readLine());
                if (length < 0) {
                    return null;
                }
                byte[] payload = readExactly(length);
                readExactly(2);
                return new String(payload, StandardCharsets.UTF_8);
            }
            case '*': {
                int count = Integer.parseInt(readLine());
                if (count < 0) {
                    return null;
                }
                List<Object> items = new ArrayList<>(count);
                for (int i = 0; i < count; i++) {
                    items.add(readReply());
                }
                return items;
            }
            default:
                throw new IOException("unexpected redis reply marker: " + (char) marker);
        }
    }

    private String readLine() throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        int previous = -1;
        while (true) {
            int b = in.read();
            if (b < 0) {
                throw new IOException("redis connection closed mid-reply");
            }
            if (previous == '\r' && b == '\n') {
                byte[] bytes = buffer.toByteArray();
                return new String(bytes, 0, Math.max(0, bytes.length - 1), StandardCharsets.UTF_8);
            }
            buffer.write(b);
            previous = b;
        }
    }

    private byte[] readExactly(int length) throws IOException {
        byte[] payload = new byte[length];
        int read = 0;
        while (read < length) {
            int n = in.read(payload, read, length - read);
            if (n < 0) {
                throw new IOException("redis connection closed mid-bulk");
            }
            read += n;
        }
        return payload;
    }

    private void closeQuietly() {
        try {
            if (socket != null) {
                socket.close();
            }
        } catch (IOException ignored) {
            // closing a dead socket is not interesting
        }
        socket = null;
        out = null;
        in = null;
    }

    @Override
    public synchronized void close() {
        closeQuietly();
    }
}
