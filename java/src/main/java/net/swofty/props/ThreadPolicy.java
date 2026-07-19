package net.swofty.props;

/**
 * Where a property write is allowed to execute. TICK writes are routed
 * through TickDispatch; ANY writes are safe from any thread.
 */
public enum ThreadPolicy {
    ANY,
    TICK
}
