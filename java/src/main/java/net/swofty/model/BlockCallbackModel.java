package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One callback inside a {@code block_handler} or {@code placement_rule}
 * declaration (W-blocks): its name (e.g. {@code on_place}, {@code tick},
 * {@code on_update}), the user-chosen positional parameter binder names, and
 * the body to run through an {@link net.swofty.ASTExecutor}.
 *
 * <p>The parameter types are fixed per (construct, callback) by the compiler
 * registry, so only the binder names travel in the AST; the runtime binds them
 * positionally to the Minestom event/state fields.
 */
public record BlockCallbackModel(String name, List<String> params, ExecuteBlock body) {
}
