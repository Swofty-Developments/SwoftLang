package net.swofty.mobs;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.instance.Instance;
import net.swofty.ScriptError;
import net.swofty.model.MobDefModel;

/**
 * Registry of mob declarations plus the global live-mob list (design 5B).
 * The live list is snapshot-copied for iteration; spawn loads the target
 * chunk implicitly through setInstance.
 */
public final class MobRegistry {
    private static final Map<String, MobDefModel> DEFS = new ConcurrentHashMap<>();
    private static final List<String> ORDER = new CopyOnWriteArrayList<>();
    private static final List<SwoftMob> LIVE = new CopyOnWriteArrayList<>();

    private MobRegistry() {
    }

    public static void clear() {
        DEFS.clear();
        ORDER.clear();
        // a re-register cycle must not orphan live mobs: dropping them from
        // the list without remove() would leave them in the world forever,
        // invisible to all_mobs() and unreachable for cleanup
        for (SwoftMob mob : LIVE) {
            net.swofty.async.TickDispatch.call(() -> {
                if (!mob.isRemoved()) {
                    mob.remove();
                }
                return null;
            });
        }
        LIVE.clear();
    }

    public static void register(MobDefModel def) {
        try {
            SwoftMob.resolveType(def.type());
            if (!def.ai().equals("melee") && !def.ai().equals("passive")
                    && !def.ai().equals("none")) {
                throw new ScriptError("unknown ai kind '" + def.ai()
                        + "' (valid: melee, passive, none)");
            }
        } catch (ScriptError e) {
            System.err.println("Error: mob '" + def.id() + "': " + e.getMessage());
            return;
        }
        if (DEFS.putIfAbsent(def.id(), def) != null) {
            System.err.println("Error: duplicate mob id '" + def.id() + "' - keeping the first");
            return;
        }
        ORDER.add(def.id());
    }

    public static MobDefModel get(String id) {
        return DEFS.get(id);
    }

    public static MobDefModel require(String id) {
        MobDefModel def = DEFS.get(id);
        if (def == null) {
            throw new ScriptError("unknown mob id '" + id + "'");
        }
        return def;
    }

    public static List<String> ids() {
        return List.copyOf(ORDER);
    }

    /** spawn mob "id" at location - returns the live mob for `as` binding. */
    public static SwoftMob spawn(String id, Pos position, Instance instance) {
        MobDefModel def = require(id);
        if (instance == null) {
            throw new ScriptError("cannot spawn mob '" + id + "': no world available");
        }
        SwoftMob mob = new SwoftMob(def);
        mob.setInstance(instance, position);
        return mob;
    }

    static void track(SwoftMob mob) {
        if (!LIVE.contains(mob)) {
            LIVE.add(mob);
        }
    }

    static void untrack(SwoftMob mob) {
        LIVE.remove(mob);
    }

    /** all_mobs([id]): snapshot of the live list, optionally filtered. */
    public static List<SwoftMob> all(String id) {
        List<SwoftMob> mobs = new ArrayList<>();
        for (SwoftMob mob : LIVE) {
            if (id == null || mob.getDef().id().equals(id)) {
                mobs.add(mob);
            }
        }
        return mobs;
    }
}
