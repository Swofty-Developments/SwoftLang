package net.swofty.event;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.PlayerEvent;
import net.swofty.ASTExecutor;
import net.swofty.event.EventPropertyResolver.Handle;
import net.swofty.event.ReceiverBinding.Arg;
import net.swofty.event.ReceiverBinding.Spec;
import net.swofty.event.events.GenericSwoftEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.SystemSender;

/**
 * Runtime dispatch for OOP receiver methods. A base-receiver method (an
 * {@link Event} carrying a {@code receiver} type) fires for every instance:
 * {@code this} binds to the receiver subject and the user's positional params
 * bind to the mapped event arguments (via {@link ReceiverBinding}), the
 * {@code event} wrapper is bound so cancellable methods can {@code cancel}, and
 * settable args flush back after a sync body runs.
 *
 * <p>Base method bodies are also indexed by {@code (receiver, method)} so a
 * more-specific custom declaration (e.g. {@code mob "ghoul"}) that OVERRIDES
 * the base can reach it with {@code default()} / {@code super.<method>(...)} —
 * most-specific-wins with an explicit escape to the base.
 */
public final class ReceiverDispatch {

    private ReceiverDispatch() {
    }

    // ------------------------------------------------------------------
    // base-method registry (for default() / super.<method>())
    // ------------------------------------------------------------------

    /**
     * A registered base receiver method body + its positional param names +
     * the receiver instance's bound noun (player/mob/item/…).
     */
    public record BaseMethod(ExecuteBlock body, List<String> params, String self) {
    }

    private static final Map<String, BaseMethod> BASE = new ConcurrentHashMap<>();

    /** Register a base receiver method so overrides can chain into it. */
    public static void registerBase(String receiver, String method, ExecuteBlock body,
            List<String> params, String self) {
        if (receiver == null || method == null || body == null) {
            return;
        }
        BASE.put(key(receiver, method), new BaseMethod(body, params, self));
    }

    /** Forget every registered base method (hot reload). */
    public static void resetBases() {
        BASE.clear();
    }

    private static String key(String receiver, String method) {
        return receiver + "#" + method;
    }

    // ------------------------------------------------------------------
    // firing a base receiver method from a live event
    // ------------------------------------------------------------------

    /**
     * Bind {@code this} + the positional params from {@code minestomEvent} and
     * run {@code swoftEvent}'s body. {@code spec} may be null — the generic
     * player fallback then binds subject = the event's player and args by
     * catalog property name, so an unmapped receiver method still runs.
     */
    public static void fire(Event swoftEvent, Spec spec,
            net.minestom.server.event.Event minestomEvent) {
        ExecuteBlock body = swoftEvent.getExecuteBlock();
        if (body == null) {
            return;
        }
        Map<String, Handle> handles = EventPropertyResolver.handlesFor(minestomEvent.getClass());
        List<String> params = swoftEvent.getParams();

        Object subject = spec != null
                ? spec.subject().read(minestomEvent, handles)
                : genericSubject(minestomEvent);
        List<Arg> argSpecs = spec != null ? spec.args() : null;

        // most-specific-wins: when the subject is a custom declaration that
        // OVERRIDES this method (e.g. `mob "ghoul" { on_click }`), the base
        // method must NOT also fire — the custom handler runs via the
        // inline-handler runtime and may chain back with default()/super.
        if (spec != null && isOverridden(spec, subject)) {
            return;
        }

        Map<String, Object> vars = new HashMap<>();
        // bind the receiver instance under its natural noun (player/mob/item/…)
        // as a bare variable; `this` was removed with the OOP-events cleanup
        if (swoftEvent.getSelf() != null) {
            vars.put(swoftEvent.getSelf(), subject);
        }
        List<Object> argValues = new ArrayList<>();
        for (int i = 0; i < params.size(); i++) {
            Object value;
            if (argSpecs != null) {
                value = i < argSpecs.size()
                        ? argSpecs.get(i).reader().read(minestomEvent, handles)
                        : NoneValue.INSTANCE;
            } else {
                value = readProp(minestomEvent, handles, params.get(i));
            }
            value = value == null ? NoneValue.INSTANCE : value;
            argValues.add(value);
            vars.put(params.get(i), value);
        }

        GenericSwoftEvent wrapper = new GenericSwoftEvent(minestomEvent, swoftEvent);
        vars.put("event", wrapper);

        CommandSender sender = senderFor(subject, argValues);
        try {
            new ASTExecutor(sender, vars).execute(body);
        } catch (Exception e) {
            System.err.println("Error in " + swoftEvent.getReceiver() + " receiver '"
                    + swoftEvent.getName() + "': " + e.getMessage());
            return;
        }

        // flush settable args back onto the underlying event (sync bodies only)
        if (argSpecs != null) {
            for (int i = 0; i < params.size() && i < argSpecs.size(); i++) {
                Arg arg = argSpecs.get(i);
                if (arg.writer() != null) {
                    try {
                        arg.writer().write(minestomEvent, handles, vars.get(params.get(i)));
                    } catch (RuntimeException ignored) {
                        // a write of an unchanged/invalid value never breaks the event
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // default() / super.<method>()
    // ------------------------------------------------------------------

    /**
     * The override context bound into a custom declaration's handler body (as
     * {@code $override}) so {@code call original method} can chain to the base
     * receiver method with the same receiver instance + args.
     */
    public record OverrideContext(String receiver, String method, Object thisValue,
            List<Object> args, Object eventWrapper, CommandSender sender) {
    }

    /**
     * {@code call original method}: run the overridden base
     * method with the handler's CURRENT bound variable values for each of the
     * base method's params (so a mutated arg like {@code damage} flows through).
     * Falls back to the args captured at dispatch time when no base method is
     * registered.
     */
    public static void invokeOriginal(OverrideContext ctx, ExecutionContext exec) {
        BaseMethod base = BASE.get(key(ctx.receiver(), ctx.method()));
        if (base == null) {
            // no base method declared — most-specific-wins with nothing to chain
            return;
        }
        List<Object> args = new ArrayList<>(base.params().size());
        for (String param : base.params()) {
            Object value = exec.getVariables().get(param);
            args.add(value == null ? NoneValue.INSTANCE : value);
        }
        runBase(ctx.receiver(), ctx.method(), ctx.thisValue(), args, ctx.eventWrapper(),
                ctx.sender());
    }

    private static void runBase(String receiver, String method, Object thisValue,
            List<Object> args, Object eventWrapper, CommandSender sender) {
        BaseMethod base = BASE.get(key(receiver, method));
        if (base == null) {
            // no base method declared — most-specific-wins with nothing to chain
            return;
        }
        Map<String, Object> vars = new HashMap<>();
        // bind the receiver instance under its natural noun (bare variable)
        if (base.self() != null) {
            vars.put(base.self(), thisValue);
        }
        List<String> params = base.params();
        for (int i = 0; i < params.size(); i++) {
            vars.put(params.get(i), i < args.size() ? args.get(i) : NoneValue.INSTANCE);
        }
        if (eventWrapper != null) {
            vars.put("event", eventWrapper);
        }
        try {
            new ASTExecutor(sender != null ? sender : consoleSender(), vars).execute(base.body());
        } catch (Exception e) {
            System.err.println("Error in base " + receiver + "." + method + ": " + e.getMessage());
        }
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    /**
     * True when the subject instance carries a custom declaration whose handler
     * overrides {@code spec.method()} — the base receiver method then yields to
     * the more-specific custom handler (which can re-enter via default()/super).
     */
    private static boolean isOverridden(Spec spec, Object subject) {
        String receiver = spec.receiver();
        String method = spec.method();
        if (subject instanceof net.swofty.mobs.SwoftMob mob
                && ("Mob".equals(receiver) || "Entity".equals(receiver))) {
            // a dedicated field (on_hit/on_spawn/on_death/on_attack) overrides
            // the base just as a generic handler does — most-specific-wins, so
            // the base receiver event must not double-fire alongside it.
            return mob.getDef() != null && mob.getDef().overridesReceiverMethod(method);
        }
        if (subject instanceof net.minestom.server.item.ItemStack stack
                && "Item".equals(receiver)) {
            String id = net.swofty.items.ItemRegistry.customId(stack);
            if (id != null) {
                net.swofty.model.ItemDefModel def = net.swofty.items.ItemRegistry.get(id);
                return def != null && def.handler(method) != null;
            }
        }
        return false;
    }

    private static Object genericSubject(net.minestom.server.event.Event event) {
        if (event instanceof PlayerEvent playerEvent) {
            try {
                Player player = playerEvent.getPlayer();
                if (player != null) {
                    return player;
                }
            } catch (Throwable ignored) {
                // fall through
            }
        }
        return NoneValue.INSTANCE;
    }

    private static Object readProp(net.minestom.server.event.Event event,
            Map<String, Handle> handles, String name) {
        Handle handle = handles.get(name.toLowerCase(Locale.ROOT));
        if (handle == null) {
            return NoneValue.INSTANCE;
        }
        return EventPropertyResolver.read(event, handle);
    }

    private static CommandSender senderFor(Object subject, List<Object> args) {
        if (subject instanceof CommandSender sender) {
            return sender;
        }
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
