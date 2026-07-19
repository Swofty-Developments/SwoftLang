package net.swofty.props;

/**
 * Sentinel for absent values. Missing variables and null property values
 * resolve to this instead of leaking Java null into scripts.
 */
public final class NoneValue {
    public static final NoneValue INSTANCE = new NoneValue();

    private NoneValue() {
    }

    public static boolean isNone(Object value) {
        return value == null || value == INSTANCE;
    }

    @Override
    public String toString() {
        return "none";
    }
}
