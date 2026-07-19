package net.swofty.nativebridge.execution.commands.http;

import net.swofty.ScriptError;
import net.swofty.http.SwoftHttpRequest;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.runtime.ExecutionContext;

/**
 * reply [code N] with &lt;string-expr&gt; (design 6B): only valid inside api
 * handlers (checker-enforced; here we require the bound request value).
 * The last reply wins; HttpRuntime flushes it after the handler returns.
 */
public class ReplyStatement extends AbstractAstNode implements Statement {
    private final Expression code;
    private final Expression body;

    public ReplyStatement(Expression code, Expression body) {
        this.code = code;
        this.body = body;
    }

    @Override
    public void execute(ExecutionContext context) {
        Object request = context.getVariables().get("request");
        if (!(request instanceof SwoftHttpRequest httpRequest)) {
            throw new ScriptError("reply is only valid inside an api handler");
        }
        int status = 200;
        if (code != null) {
            Object value = context.evaluate(code);
            if (!(value instanceof Number number)) {
                throw new ScriptError("reply code must be a number, got: " + value);
            }
            status = number.intValue();
            if (status < 100 || status > 599) {
                throw new ScriptError("reply code must be 100-599, got: " + status);
            }
        }
        httpRequest.reply(status, body != null ? context.evaluateString(body) : "");
    }
}
