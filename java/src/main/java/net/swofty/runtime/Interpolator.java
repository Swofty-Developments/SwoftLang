package net.swofty.runtime;

import java.util.function.UnaryOperator;

import net.swofty.props.NoneValue;

/**
 * ${...} interpolation glue: variable paths resolve through the context
 * and none renders as the empty string.
 */
public final class Interpolator {
    private Interpolator() {
    }

    /**
     * Interpolate variables in a string
     */
    public static String interpolate(ExecutionContext context, String text) {
        return interpolate(context, text, UnaryOperator.identity());
    }

    /**
     * Interpolate variables in a string, transforming each interpolated
     * {@code ${...}} value (but never the surrounding literal template text)
     * through {@code valueMapper}. The literal path uses the identity mapper
     * and is byte-for-byte identical to the two-arg overload; callers that
     * feed the result to a markup parser (e.g. MiniMessage) pass an escaper so
     * user-controlled values can only ever contribute plain text.
     */
    public static String interpolate(ExecutionContext context, String text,
            UnaryOperator<String> valueMapper) {
        StringBuilder result = new StringBuilder();
        int i = 0;

        while (i < text.length()) {
            if (text.charAt(i) == '$' && i + 1 < text.length() && text.charAt(i + 1) == '{') {
                // Find the closing brace
                int closeIndex = text.indexOf('}', i + 2);
                if (closeIndex != -1) {
                    String varName = text.substring(i + 2, closeIndex);
                    Object value = context.getVariable(varName);
                    String rendered = NoneValue.isNone(value) ? "" : Values.displayString(value);
                    result.append(valueMapper.apply(rendered));
                    i = closeIndex + 1;
                    continue;
                }
            }
            result.append(text.charAt(i));
            i++;
        }

        return result.toString();
    }
}
