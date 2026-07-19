package net.swofty.handlers;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.swofty.ASTExecutor;
import net.swofty.event.events.GenericSwoftEvent;
import net.swofty.model.InlineHandler;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.runtime.SystemSender;

/**
 * Shared dispatch machinery for first-class inline handlers
 * (W-inline-handlers), generalized out of the mob {@code on_hit} path
 * (SwoftMob.runHandler): run a sync-colored handler body through an
 * {@link ASTExecutor} with a bound variable map, swallowing script errors so a
 * misbehaving handler never takes down the firing event.
 *
 * <p>{@link #dispatch} adds the per-(kind, event) binding convention every
 * inline handler shares: {@code this} is the involved instance (Mob entity,
 * ItemStack, Hologram/Npc), the handler's declared parameter names bind
 * positionally to the event arguments, and — for cancellable events — an
 * {@code event} wrapper is bound so the body's {@code cancel} statement vetoes
 * through the underlying Minestom {@code CancellableEvent}. The boolean return
 * reports whether the body cancelled.
 */
public final class HandlerDispatch {

    private HandlerDispatch() {
    }

    /**
     * Run {@code body} with {@code vars} bound, reusing the exact ASTExecutor
     * invocation + error isolation the mob on_hit path uses. No-op for a
     * null/empty block.
     */
    public static void run(CommandSender sender, ExecuteBlock body, Map<String, Object> vars,
            String label) {
        if (body == null || body.isEmpty()) {
            return;
        }
        try {
            new ASTExecutor(sender != null ? sender : consoleSender(), vars).execute(body);
        } catch (Exception e) {
            System.err.println("Error in " + label + " handler: " + e.getMessage());
        }
    }

    /**
     * Bind {@code this} + the handler's positional params (+ an {@code event}
     * wrapper when a cancellable Minestom event is supplied) and run the body.
     *
     * @param handler       the resolved inline handler (its declared param
     *                      names drive the positional binding)
     * @param thisValue     the involved instance, bound as {@code this}
     * @param cancellable   the underlying Minestom event to expose for
     *                      {@code cancel}, or null for non-cancellable handlers
     * @param label         diagnostic label for error messages
     * @param args          event arguments, bound positionally to the handler's
     *                      declared parameter names
     * @return true if the body cancelled the event
     */
    public static boolean dispatch(InlineHandler handler, Object thisValue,
            net.minestom.server.event.Event cancellable, String label, Object... args) {
        Map<String, Object> vars = new HashMap<>();
        vars.put("this", thisValue);
        List<String> params = handler.params();
        for (int i = 0; i < params.size() && i < args.length; i++) {
            vars.put(params.get(i), args[i]);
        }
        GenericSwoftEvent wrapper = cancellable == null
                ? null : new GenericSwoftEvent(cancellable, null);
        if (wrapper != null) {
            vars.put("event", wrapper);
        }
        run(senderFor(args), handler.body(), vars, label);
        return wrapper != null && wrapper.isCancelled();
    }

    /** Prefer a player argument as the executor sender; else the console. */
    private static CommandSender senderFor(Object[] args) {
        for (Object arg : args) {
            if (arg instanceof CommandSender sender) {
                return sender;
            }
        }
        return consoleSender();
    }

    static CommandSender consoleSender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
