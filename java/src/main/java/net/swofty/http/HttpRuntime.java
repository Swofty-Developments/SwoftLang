package net.swofty.http;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import net.swofty.ASTExecutor;
import net.swofty.async.AsyncRuntime;
import net.swofty.model.ApiHandlerModel;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;
import net.swofty.runtime.SystemSender;

/**
 * The script HTTP server (design 6B): JDK com.sun.net.httpserver with a
 * virtual-thread-per-request executor. Each request routes through the
 * path-param router and runs its api handler as a script task ON the
 * serving virtual thread (async color: wait/TickDispatch work normally),
 * then the reply written by the reply statement is flushed; handlers
 * that never reply answer 204, handler errors answer 500.
 */
public final class HttpRuntime {
    private static volatile HttpServer server;
    /**
     * The routes of the CURRENT start(): each (re)start builds a fresh
     * router and swaps it in atomically, so a reload never accumulates
     * stale routes (the old sorted list would keep shadowing same-path
     * routes) and in-flight requests never see a mid-registration list
     */
    private static volatile HttpRouter router = new HttpRouter();

    private HttpRuntime() {
    }

    public static synchronized void start(String bind, int port, List<ApiHandlerModel> handlers)
            throws IOException {
        stop();
        HttpRouter fresh = new HttpRouter();
        for (ApiHandlerModel handler : handlers) {
            fresh.register(handler);
        }
        router = fresh;
        HttpServer created = HttpServer.create(new InetSocketAddress(bind, port), 0);
        created.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        created.createContext("/", HttpRuntime::handle);
        created.start();
        server = created;
        System.out.println("[http] serving " + fresh.size() + " api route(s) on "
                + bind + ":" + created.getAddress().getPort());
    }

    /** The port actually bound (for port-0 harness starts). */
    public static int boundPort() {
        HttpServer current = server;
        return current != null ? current.getAddress().getPort() : -1;
    }

    public static synchronized void stop() {
        HttpServer current = server;
        if (current != null) {
            current.stop(0);
            server = null;
        }
    }

    private static void handle(HttpExchange exchange) throws IOException {
        String method = exchange.getRequestMethod();
        String path = exchange.getRequestURI().getPath();
        HttpRouter.Match match = router.match(method, path);
        if (match == null) {
            respond(exchange, 404, "no api route matches " + method + " " + path + "\n");
            return;
        }

        String body = readBody(exchange.getRequestBody());
        SwoftHttpRequest request = new SwoftHttpRequest(
                method.toUpperCase(),
                path,
                exchange.getRequestURI().getRawQuery(),
                body,
                match.params());

        try {
            // the api handler is async-colored: run it as a script task on
            // this virtual thread so wait/spawn/TickDispatch all behave
            AsyncRuntime.runInline("api " + method + " " + path, () -> {
                Map<String, Object> variables = new HashMap<>();
                variables.put("request", request);
                new ASTExecutor(SystemSender.INSTANCE, variables)
                        .execute(match.handler().execute());
            });
        } catch (Throwable t) {
            System.err.println("[http] handler for " + path + " failed: " + t);
            t.printStackTrace();
            respond(exchange, 500, "internal script error\n");
            return;
        }

        if (request.hasReply()) {
            respond(exchange, request.replyCode(), request.replyBody());
        } else {
            respond(exchange, 204, "");
        }
    }

    private static String readBody(InputStream stream) throws IOException {
        try (stream) {
            return new String(stream.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private static void respond(HttpExchange exchange, int code, String body) throws IOException {
        byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
        if (!exchange.getResponseHeaders().containsKey("Content-Type")) {
            exchange.getResponseHeaders().add("Content-Type", "text/plain; charset=utf-8");
        }
        // 204 must not carry a body
        exchange.sendResponseHeaders(code, code == 204 ? -1 : bytes.length);
        if (code != 204) {
            try (OutputStream out = exchange.getResponseBody()) {
                out.write(bytes);
            }
        } else {
            exchange.close();
        }
    }

    /** request.* property rows (design 6B). */
    public static void registerProperties() {
        PropertyRegistry.register(PropertyDef.readOnly("method", SwoftHttpRequest.class,
                SwoftHttpRequest::method));
        PropertyRegistry.register(PropertyDef.readOnly("path", SwoftHttpRequest.class,
                SwoftHttpRequest::path));
        PropertyRegistry.register(PropertyDef.readOnly("query", SwoftHttpRequest.class,
                SwoftHttpRequest::query));
        PropertyRegistry.register(PropertyDef.readOnly("body", SwoftHttpRequest.class,
                SwoftHttpRequest::body));
        // params is a Map: request.params.<name> is a plain map hop
        PropertyRegistry.register(PropertyDef.readOnly("params", SwoftHttpRequest.class,
                SwoftHttpRequest::params));
    }
}
