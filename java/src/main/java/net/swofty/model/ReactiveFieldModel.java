package net.swofty.model;

import java.util.Map;

/**
 * A reactive struct field (§4.1): a struct field annotated {@code @EventReceiver}
 * that declares event handlers on the value it holds. {@code field} is the field
 * name (the subject bound as a bare var in the handler bodies); {@code subject}
 * is the field's receiver type name (e.g. "Player", "Mob") which picks the event
 * vocabulary; {@code handlers} maps each handler method (e.g. "on_death") to its
 * body + positional param binders.
 *
 * <p>Emitted by the compiler under a struct's {@code "reactive"} array as
 * {@code {field, subject, handlers:{method:{subject,params,body}}}}. A live
 * instance of the owning struct (reachable from a persistent root, §4.2) drives
 * these handlers whenever a native event fires for the value in {@code field}.
 */
public record ReactiveFieldModel(
        String field,
        String subject,
        Map<String, InlineHandler> handlers,
        int line,
        int col) {
}
