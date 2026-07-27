package net.swofty.model;

/**
 * storage { on_handoff_failure: ... } (design 1.10.0 §1): what to do when this
 * server cannot take ownership of a joining player's session-owned values —
 * the backend is unreachable or the previous holder's lease has not been
 * released and has not yet expired.
 *
 * <p>The ONLY safe outcomes are ones that do not let the player play with
 * unowned data: serving defaults would duplicate/erase their progress. The
 * default action is {@code kick} with a reconnect-in-a-moment message.
 */
public record HandoffFailureModel(String action, String message) {

    /** Default message when the storage block does not spell one out. */
    public static final String DEFAULT_MESSAGE =
            "Loading your data - reconnect in a moment";

    /** The engine default: kick with {@link #DEFAULT_MESSAGE}. */
    public static HandoffFailureModel defaultKick() {
        return new HandoffFailureModel("kick", DEFAULT_MESSAGE);
    }

    /** The message to show, falling back to {@link #DEFAULT_MESSAGE}. */
    public String messageOrDefault() {
        return message == null || message.isBlank() ? DEFAULT_MESSAGE : message;
    }
}
