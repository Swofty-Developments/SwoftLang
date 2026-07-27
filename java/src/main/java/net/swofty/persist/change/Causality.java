package net.swofty.persist.change;

import java.util.List;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Layer 3 of the cascade guards (design 1.10.0 §5.3): the propagating causality
 * token and the depth cap.
 *
 * <p>Every persistent write asks {@link #forWrite} for its token. A write made
 * from ordinary script code starts a fresh chain at depth 0; a write made
 * INSIDE a change handler inherits that handler's chain at depth + 1, because
 * {@link ChangeDispatcher} publishes the change's token to this thread
 * ({@link #enter}) for the duration of the handler body. Once the chain passes
 * the cap the write is REJECTED and logged with the whole chain path — never
 * silently dropped, because a number that quietly stops updating is far worse
 * to debug than a loud line in the console.
 *
 * <p>The cap is per CHAIN, not per server: the token rides the broadcast (see
 * {@link CausalityToken}), so a cross-server cascade keeps counting instead of
 * resetting to 0 on every hop.
 */
public final class Causality {

    /** §5.3 default depth cap. */
    public static final int DEFAULT_CAP = 8;

    private static final String CAP_PROPERTY = "swoft.persist.cascade_depth";

    private static final ThreadLocal<CausalityToken> CURRENT = new ThreadLocal<>();

    private static final AtomicLong CHAINS = new AtomicLong();

    private Causality() {
    }

    /** The configured cascade depth cap. */
    public static int cap() {
        try {
            String configured = System.getProperty(CAP_PROPERTY);
            if (configured != null) {
                return Math.max(1, Integer.parseInt(configured.trim()));
            }
        } catch (Exception ignored) {
            // a malformed override falls back to the documented default
        }
        return DEFAULT_CAP;
    }

    /** The chain this thread is currently executing a change handler for, or null. */
    public static CausalityToken current() {
        return CURRENT.get();
    }

    /**
     * The token for a write that is about to happen, or {@code null} when the
     * cascade guard REJECTS it (already logged, loudly, with the chain path).
     */
    public static CausalityToken forWrite(String serverId, String var, String key) {
        CausalityToken parent = CURRENT.get();
        if (parent == null) {
            return new CausalityToken(newChainId(serverId), serverId, 0,
                    List.of(CausalityToken.step(var, key)));
        }
        CausalityToken next = parent.deeper(var, key);
        int cap = cap();
        if (next.depth() > cap) {
            System.err.println("[persist] change cascade exceeded depth " + cap
                    + ", write to '" + CausalityToken.step(var, key)
                    + "' rejected  chain: " + next.describePath()
                    + "  (chain " + next.chain() + " started on '"
                    + next.originServer() + "')");
            return null;
        }
        return next;
    }

    /**
     * Run a change handler under {@code token}: writes it makes inherit the
     * chain at depth + 1. Returns the token to hand back to {@link #exit}, so
     * nested inline dispatch restores rather than clears.
     */
    public static CausalityToken enter(CausalityToken token) {
        CausalityToken previous = CURRENT.get();
        CURRENT.set(token);
        return previous;
    }

    /** Restore what {@link #enter} displaced. */
    public static void exit(CausalityToken previous) {
        if (previous == null) {
            CURRENT.remove();
        } else {
            CURRENT.set(previous);
        }
    }

    private static String newChainId(String serverId) {
        return serverId + '#' + CHAINS.incrementAndGet();
    }
}
