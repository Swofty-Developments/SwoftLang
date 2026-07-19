package net.swofty.http;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * The request value bound as {@code request} inside api handlers (design
 * 6B): read-only method/path/query/body plus the path-param map exposed
 * as {@code request.params.<name>} (Map property hops resolve naturally
 * through PathResolver). Reply state is written by the reply statement
 * and consumed by HttpRuntime after the handler returns.
 */
public final class SwoftHttpRequest {
    private final String method;
    private final String path;
    private final String query;
    private final String body;
    private final Map<String, Object> params;

    private volatile int replyCode = -1;
    private volatile String replyBody;

    public SwoftHttpRequest(String method, String path, String query, String body,
            Map<String, Object> params) {
        this.method = method;
        this.path = path;
        this.query = query != null ? query : "";
        this.body = body != null ? body : "";
        this.params = new LinkedHashMap<>(params);
    }

    public String method() {
        return method;
    }

    public String path() {
        return path;
    }

    public String query() {
        return query;
    }

    public String body() {
        return body;
    }

    public Map<String, Object> params() {
        return params;
    }

    public void reply(int code, String body) {
        this.replyCode = code;
        this.replyBody = body;
    }

    public boolean hasReply() {
        return replyCode > 0;
    }

    public int replyCode() {
        return replyCode;
    }

    public String replyBody() {
        return replyBody != null ? replyBody : "";
    }

    @Override
    public String toString() {
        return method + " " + path;
    }
}
