package net.swofty.runtime;

/**
 * The {@code server} pseudo-variable (design 6B/6D): a singleton whose
 * property rows expose tps/average_tps/mspt (TpsMonitor) and the
 * runtime-settable motd. Resolved as an implicit root by
 * ExecutionContext when no script variable shadows the name.
 */
public final class ServerValue {
    public static final ServerValue INSTANCE = new ServerValue();

    private ServerValue() {
    }

    @Override
    public String toString() {
        return "server";
    }
}
