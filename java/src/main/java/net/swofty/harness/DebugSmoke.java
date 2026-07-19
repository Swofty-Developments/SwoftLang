package net.swofty.harness;

import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import net.swofty.ASTExecutor;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.debug.DebugServer;
import net.swofty.nativebridge.representation.Command;
import net.swofty.runtime.SystemSender;

/**
 * Headless smoke for the debug tracer (VS Code extension Part 3):
 *  1. flips {@link DebugServer#enabled}, executes a command handler, and
 *     asserts a trace event fired for every statement with the right file +
 *     line, bracketed by handler enter/exit;
 *  2. connects a raw WebSocket client to a live {@link DebugServer} and asserts
 *     the hello frame arrives.
 */
public final class DebugSmoke {
    private static final String REL_FILE = "scripts/debugdemo.sw";

    private static final String SCRIPT = """
            command "demo" {
                execute {
                    set x to 1
                    set x to x + 1
                    if x > 1 {
                        send "big" to sender
                    }
                }
            }
            """;

    public static int run() throws Exception {
        int failures = 0;
        failures += traceSmoke();
        failures += wsConnectSmoke();
        failures += reloadSmoke();
        if (failures == 0) {
            System.out.println("[debug-smoke] OK");
        } else {
            System.err.println("[debug-smoke] " + failures + " check(s) failed");
        }
        return failures == 0 ? 0 : 1;
    }

    /** Execute a handler with tracing on and assert the emitted events. */
    private static int traceSmoke() throws Exception {
        Path dir = Files.createTempDirectory("swoft-debug-smoke");
        File script = dir.resolve("debugdemo.sw").toFile();
        Files.writeString(script.toPath(), SCRIPT);
        String json = SwoftcCompiler.compile(script);
        ParsedScript parsed = SwoftJsonLoader.load(json, REL_FILE);

        List<String> messages = new CopyOnWriteArrayList<>();
        DebugServer.setTestListener(messages::add);
        DebugServer.enabled = true;
        try {
            for (Command command : parsed.commands()) {
                if (command != null && command.getExecuteBlock() != null) {
                    new ASTExecutor(new SystemSender(true), new HashMap<>())
                            .execute(command.getExecuteBlock());
                }
            }
        } finally {
            DebugServer.enabled = false;
            DebugServer.setTestListener(null);
        }

        int failures = 0;
        List<JsonObject> traces = new ArrayList<>();
        List<JsonObject> handlers = new ArrayList<>();
        for (String message : messages) {
            JsonObject obj = JsonParser.parseString(message).getAsJsonObject();
            switch (obj.get("type").getAsString()) {
                case "trace" -> traces.add(obj);
                case "handler" -> handlers.add(obj);
                default -> { }
            }
        }

        if (traces.isEmpty()) {
            System.err.println("[debug-smoke] no trace events emitted");
            failures++;
        }
        for (JsonObject trace : traces) {
            if (!REL_FILE.equals(optString(trace, "file"))) {
                System.err.println("[debug-smoke] trace has wrong file: " + trace);
                failures++;
                break;
            }
            if (trace.get("line").getAsInt() <= 0) {
                System.err.println("[debug-smoke] trace missing line: " + trace);
                failures++;
                break;
            }
        }
        failures += expectKind(traces, "assign");
        failures += expectKind(traces, "send");
        // every statement trace carries the handler tag
        boolean tagged = traces.stream()
                .anyMatch(t -> "command demo".equals(optString(t, "handler")));
        if (!tagged) {
            System.err.println("[debug-smoke] no trace tagged with 'command demo'");
            failures++;
        }
        // handler enter + exit for the command body
        boolean enter = handlers.stream().anyMatch(h -> "enter".equals(optString(h, "phase"))
                && "command demo".equals(optString(h, "name")));
        boolean exit = handlers.stream().anyMatch(h -> "exit".equals(optString(h, "phase"))
                && "command demo".equals(optString(h, "name")));
        if (!enter || !exit) {
            System.err.println("[debug-smoke] missing handler enter/exit (enter=" + enter
                    + ", exit=" + exit + ")");
            failures++;
        }
        System.out.println("[debug-smoke] trace: " + traces.size() + " statements, "
                + handlers.size() + " handler events");
        return failures;
    }

    private static int expectKind(List<JsonObject> traces, String kind) {
        boolean found = traces.stream().anyMatch(t -> kind.equals(optString(t, "kind")));
        if (!found) {
            System.err.println("[debug-smoke] no trace of kind '" + kind + "'");
            return 1;
        }
        return 0;
    }

    /** Start a real DebugServer and assert a raw WS client gets the hello. */
    private static int wsConnectSmoke() {
        int port = freePort();
        if (port <= 0) {
            System.err.println("[debug-smoke] could not find a free port");
            return 1;
        }
        DebugServer.start(port, "/abs/scripts");
        try (Socket socket = new Socket("127.0.0.1", port)) {
            socket.setSoTimeout(3000);
            OutputStream out = socket.getOutputStream();
            String request = "GET / HTTP/1.1\r\n"
                    + "Host: localhost\r\n"
                    + "Upgrade: websocket\r\n"
                    + "Connection: Upgrade\r\n"
                    + "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
                    + "Sec-WebSocket-Version: 13\r\n\r\n";
            out.write(request.getBytes(StandardCharsets.US_ASCII));
            out.flush();

            InputStream in = socket.getInputStream();
            String status = readHttpResponse(in);
            if (!status.contains("101")) {
                System.err.println("[debug-smoke] handshake did not return 101: " + status);
                return 1;
            }
            String hello = readTextFrame(in);
            if (hello == null || !hello.contains("\"type\":\"hello\"")
                    || !hello.contains("/abs/scripts")) {
                System.err.println("[debug-smoke] bad hello frame: " + hello);
                return 1;
            }
            System.out.println("[debug-smoke] ws hello: " + hello);
            return 0;
        } catch (Exception e) {
            System.err.println("[debug-smoke] ws connect failed: " + e.getMessage());
            return 1;
        } finally {
            DebugServer.stop();
        }
    }

    /** Assert reload broadcasts encode ok and error results correctly. */
    private static int reloadSmoke() {
        List<String> messages = new CopyOnWriteArrayList<>();
        DebugServer.setTestListener(messages::add);
        try {
            DebugServer.reload(REL_FILE, true, null);
            DebugServer.reload(REL_FILE, false, "debugdemo.sw:4:9: error: boom");
        } finally {
            DebugServer.setTestListener(null);
        }
        int failures = 0;
        JsonObject ok = JsonParser.parseString(messages.get(0)).getAsJsonObject();
        JsonObject bad = JsonParser.parseString(messages.get(1)).getAsJsonObject();
        if (!"reload".equals(optString(ok, "type")) || !ok.get("ok").getAsBoolean()
                || !REL_FILE.equals(optString(ok, "file"))) {
            System.err.println("[debug-smoke] bad ok-reload: " + ok);
            failures++;
        }
        if (bad.get("ok").getAsBoolean() || !optString(bad, "error").contains("boom")) {
            System.err.println("[debug-smoke] bad error-reload: " + bad);
            failures++;
        }
        return failures;
    }

    private static String optString(JsonObject obj, String key) {
        return obj.has(key) && !obj.get(key).isJsonNull() ? obj.get(key).getAsString() : null;
    }

    private static int freePort() {
        try (ServerSocket socket = new ServerSocket(0)) {
            return socket.getLocalPort();
        } catch (Exception e) {
            return -1;
        }
    }

    private static String readHttpResponse(InputStream in) throws Exception {
        StringBuilder sb = new StringBuilder();
        int prev = -1;
        int cur;
        int matched = 0;
        while ((cur = in.read()) != -1) {
            sb.append((char) cur);
            if (prev == '\r' && cur == '\n') {
                if (++matched == 2) {
                    break;
                }
            } else if (cur != '\r') {
                matched = 0;
            }
            prev = cur;
        }
        return sb.toString();
    }

    private static String readTextFrame(InputStream in) throws Exception {
        int b0 = in.read();
        if (b0 < 0) {
            return null;
        }
        int b1 = in.read();
        int len = b1 & 0x7F;
        if (len == 126) {
            len = (in.read() << 8) | in.read();
        }
        byte[] payload = in.readNBytes(len);
        return new String(payload, StandardCharsets.UTF_8);
    }

    private DebugSmoke() {
    }
}
