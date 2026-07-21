package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One first-class inline handler (W-inline-handlers): an {@code on_<event>}
 * block declared inside a mob/item/hologram/npc declaration. Emitted by the
 * compiler under the declaration's {@code "handlers"} object as
 * {@code {event: {params:[...], body:{...}}}}.
 *
 * <p>{@code self} is the receiver instance's natural noun (mob/item/block/…)
 * bound as a bare variable; {@code params} are the event's canonical arg names
 * in declaration order (types fixed per (kind, event) by the compiler
 * registry). The runtime dispatcher binds {@code self} to the involved instance
 * plus each param name positionally to that event's arguments before running
 * {@code body} through an {@link net.swofty.ASTExecutor}. Bodies are
 * sync-colored.
 */
public record InlineHandler(String self, List<String> params, ExecuteBlock body) {

    /** Legacy shape without a bound self noun. */
    public InlineHandler(List<String> params, ExecuteBlock body) {
        this(null, params, body);
    }
}
