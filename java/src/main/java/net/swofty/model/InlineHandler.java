package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One first-class inline handler (W-inline-handlers): an {@code on_<event>}
 * block declared inside a mob/item/hologram/npc declaration. Emitted by the
 * compiler under the declaration's {@code "handlers"} object as
 * {@code {event: {params:[...], body:{...}}}}.
 *
 * <p>{@code params} are the user-chosen binder names in declaration order (the
 * types are fixed per (kind, event) by the compiler registry); the runtime
 * dispatcher binds {@code this} to the involved instance plus each param name
 * positionally to that event's arguments before running {@code body} through an
 * {@link net.swofty.ASTExecutor}. Bodies are sync-colored.
 */
public record InlineHandler(List<String> params, ExecuteBlock body) {
}
