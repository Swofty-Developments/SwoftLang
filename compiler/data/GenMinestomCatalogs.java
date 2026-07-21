// GenMinestomCatalogs — generates compiler/data/events.json, entity-api.json and
// events_data.ml from the pinned Minestom jar (ebaa2bbf64).
//
// Regenerate with (CP = full runtime classpath of the :java gradle module, i.e. the
// pinned minestom-snapshots-ebaa2bbf64.jar plus all of its transitive deps from
// ~/.gradle/caches — reflection needs supertypes/signature types resolvable):
//
//   javac -d /tmp/gencat compiler/data/GenMinestomCatalogs.java
//   java -cp "/tmp/gencat:$CP" GenMinestomCatalogs \
//       /path/to/minestom-snapshots-ebaa2bbf64.jar /mnt/work/VSC/SwoftLang/compiler/data
//
// Output is deterministic (sorted, no timestamps) so the files are diff-stable.

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.io.FileWriter;
import java.io.Writer;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.lang.reflect.RecordComponent;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

public final class GenMinestomCatalogs {

    static final String COMMIT = "2026.07.12-26.2";
    static final Gson GSON = new GsonBuilder().setPrettyPrinting().disableHtmlEscaping().create();

    public static void main(String[] args) throws Exception {
        String jarPath = args[0];
        Path outDir = Path.of(args[1]);
        Files.createDirectories(outDir);

        String sha = sha256(jarPath);
        JsonObject events = genEvents(jarPath, sha);
        write(outDir.resolve("events.json"), events);
        writeOcamlFragment(outDir.resolve("events_data.ml"), events);
        JsonObject entityApi = genEntityApi(sha);
        write(outDir.resolve("entity-api.json"), entityApi);
        JsonObject packets = genPackets(jarPath, sha);
        write(outDir.resolve("packets.json"), packets);

        // ---- sanity summary to stdout ----
        JsonArray evs = events.getAsJsonArray("events");
        long cancellable = 0;
        List<String> fishing = new ArrayList<>();
        for (var e : evs) {
            JsonObject o = e.getAsJsonObject();
            if (o.get("cancellable").getAsBoolean()) cancellable++;
            if (o.get("className").getAsString().toLowerCase().contains("fish"))
                fishing.add(o.get("className").getAsString());
        }
        System.out.println("events=" + evs.size());
        System.out.println("cancellable=" + cancellable);
        System.out.println("fishing=" + fishing);
        System.out.println("nonEventConcretePublicClasses="
                + events.getAsJsonObject("_meta").getAsJsonArray("nonEventConcretePublicClasses").size());
        System.out.println("loadErrors="
                + events.getAsJsonObject("_meta").getAsJsonArray("loadErrors").size());
        JsonObject pmeta = packets.getAsJsonObject("_meta");
        System.out.println("packets=" + pmeta.get("count").getAsInt()
                + " (client=" + pmeta.get("clientCount").getAsInt()
                + ", server=" + pmeta.get("serverCount").getAsInt() + ")");
        System.out.println("packetLoadErrors=" + pmeta.getAsJsonArray("loadErrors").size());
    }

    // ================= packets.json =================
    //
    // One entry per concrete public record under net.minestom.server.network.packet.**
    // that implements ClientPacket (inbound — the packets a `Packet { on "..." }` block
    // listens to) or ServerPacket (outbound). Record components are the packet fields;
    // javaType -> ty uses the SAME table as the events catalog (see tyOfJavaType, mirrored
    // from compiler/lib/registry.ml ty_of_java_type). Exotic types collapse to "TAny".

    static JsonObject genPackets(String jarPath, String sha) throws Exception {
        Class<?> clientItf = Class.forName("net.minestom.server.network.packet.client.ClientPacket");
        Class<?> serverItf = Class.forName("net.minestom.server.network.packet.server.ServerPacket");

        TreeMap<String, Class<?>> packetClasses = new TreeMap<>();
        List<String> loadErrors = new ArrayList<>();
        try (JarFile jar = new JarFile(jarPath)) {
            Enumeration<JarEntry> en = jar.entries();
            while (en.hasMoreElements()) {
                JarEntry je = en.nextElement();
                String n = je.getName();
                if (!n.startsWith("net/minestom/server/network/packet/") || !n.endsWith(".class")) continue;
                String cn = n.substring(0, n.length() - ".class".length()).replace('/', '.');
                Class<?> c;
                try {
                    c = Class.forName(cn, false, GenMinestomCatalogs.class.getClassLoader());
                } catch (Throwable t) {
                    loadErrors.add(cn + " : " + t);
                    continue;
                }
                int m = c.getModifiers();
                if (!Modifier.isPublic(m) || Modifier.isAbstract(m) || c.isInterface()
                        || c.isAnnotation() || c.isEnum() || c.isSynthetic()
                        || c.isAnonymousClass() || c.isLocalClass()) continue;
                boolean isClient = clientItf.isAssignableFrom(c);
                boolean isServer = serverItf.isAssignableFrom(c);
                if (!isClient && !isServer) continue;
                packetClasses.put(cn, c);
            }
        }
        loadErrors.sort(String::compareTo);

        JsonObject root = new JsonObject();
        JsonObject meta = new JsonObject();
        meta.addProperty("generator",
                "compiler/data/GenMinestomCatalogs.java (same command as events.json)");
        meta.addProperty("minestomCommit", COMMIT);
        meta.addProperty("jarSha256", sha);
        meta.addProperty("scope",
                "every concrete public record under net.minestom.server.network.packet.** that "
              + "implements net.minestom.server.network.packet.client.ClientPacket (direction "
              + "\"client\", inbound — listened to by Packet { on \"...\" }) or "
              + "net.minestom.server.network.packet.server.ServerPacket (direction \"server\", outbound)");
        meta.addProperty("fieldRules",
                "one entry per record component; name = snake_case of the component; accessor = the "
              + "record accessor method; javaType = generic component type; ty = SwoftLang type from "
              + "the SAME javaType->ty table as the events catalog (compiler/lib/registry.ml "
              + "ty_of_java_type), exotic types -> \"TAny\"");

        int clientCount = 0, serverCount = 0;
        for (Map.Entry<String, Class<?>> e : packetClasses.entrySet()) {
            Class<?> c = e.getValue();
            boolean isClient = clientItf.isAssignableFrom(c);
            JsonObject o = new JsonObject();
            o.addProperty("simple_name", c.getSimpleName());
            o.addProperty("direction", isClient ? "client" : "server");
            o.add("fields", packetFields(c, loadErrors));
            root.add(e.getKey(), o);
            if (isClient) clientCount++; else serverCount++;
        }

        meta.addProperty("count", packetClasses.size());
        meta.addProperty("clientCount", clientCount);
        meta.addProperty("serverCount", serverCount);
        JsonArray le = new JsonArray(); loadErrors.forEach(le::add);
        meta.add("loadErrors", le);
        root.add("_meta", meta);
        return root;
    }

    static JsonArray packetFields(Class<?> c, List<String> errors) {
        JsonArray out = new JsonArray();
        try {
            if (!c.isRecord()) return out;
            for (RecordComponent rc : c.getRecordComponents()) {
                String javaType = rc.getGenericType().getTypeName();
                JsonObject p = new JsonObject();
                p.addProperty("name", snake(rc.getName()));
                p.addProperty("accessor", rc.getName());
                p.addProperty("javaType", javaType);
                p.addProperty("ty", tyOfJavaType(javaType));
                out.add(p);
            }
        } catch (Throwable t) {
            errors.add(c.getName() + " (fields) : " + t);
        }
        return out;
    }

    /**
     * javaType -> SwoftLang ty constructor name. Mirror of ty_of_java_type in
     * compiler/lib/registry.ml (keep the two in lockstep). Anything not listed -> "TAny".
     */
    static String tyOfJavaType(String javaType) {
        int lt = javaType.indexOf('<');
        String base = lt >= 0 ? javaType.substring(0, lt) : javaType;
        switch (base) {
            case "net.minestom.server.entity.Player":
                return "TPlayer";
            case "net.minestom.server.entity.Entity":
            case "net.minestom.server.entity.LivingEntity":
            case "net.minestom.server.entity.ItemEntity":
            case "net.minestom.server.entity.ExperienceOrb":
                return "TEntity";
            case "net.minestom.server.item.ItemStack":
                return "TItem";
            case "net.minestom.server.instance.block.Block":
                return "TString";
            case "net.minestom.server.coordinate.Pos":
            case "net.minestom.server.coordinate.Point":
            case "net.minestom.server.coordinate.BlockVec":
                return "TLocation";
            case "net.minestom.server.coordinate.Vec":
                return "TVec";
            case "net.minestom.server.instance.Instance":
                return "TWorld";
            case "net.kyori.adventure.text.Component":
            case "java.lang.String":
                return "TString";
            case "boolean":
            case "java.lang.Boolean":
                return "TBoolean";
            case "int":
            case "byte":
            case "short":
            case "long":
            case "java.lang.Integer":
            case "java.lang.Byte":
            case "java.lang.Short":
            case "java.lang.Long":
                return "TInteger";
            case "double":
            case "float":
            case "java.lang.Double":
            case "java.lang.Float":
                return "TDouble";
            case "net.minestom.server.entity.GameMode":
            case "net.minestom.server.entity.PlayerHand":
            case "net.minestom.server.instance.block.BlockFace":
            case "net.minestom.server.inventory.click.ClickType":
            case "net.minestom.server.item.ItemAnimation":
            case "net.minestom.server.sound.SoundEvent":
                return "TString";
            case "net.minestom.server.entity.damage.Damage":
                return "TDouble";
            default:
                return "TAny";
        }
    }

    // ================= events.json =================

    static JsonObject genEvents(String jarPath, String sha) throws Exception {
        Class<?> eventItf = Class.forName("net.minestom.server.event.Event");
        Class<?> cancellableItf = Class.forName("net.minestom.server.event.trait.CancellableEvent");

        TreeMap<String, Class<?>> eventClasses = new TreeMap<>();
        List<String> nonEvent = new ArrayList<>();
        List<String> loadErrors = new ArrayList<>();

        try (JarFile jar = new JarFile(jarPath)) {
            Enumeration<JarEntry> en = jar.entries();
            while (en.hasMoreElements()) {
                JarEntry je = en.nextElement();
                String n = je.getName();
                if (!n.startsWith("net/minestom/server/event/") || !n.endsWith(".class")) continue;
                String cn = n.substring(0, n.length() - ".class".length()).replace('/', '.');
                Class<?> c;
                try {
                    c = Class.forName(cn, false, GenMinestomCatalogs.class.getClassLoader());
                } catch (Throwable t) {
                    loadErrors.add(cn + " : " + t);
                    continue;
                }
                int m = c.getModifiers();
                if (!Modifier.isPublic(m) || Modifier.isAbstract(m) || c.isInterface()
                        || c.isAnnotation() || c.isEnum() || c.isSynthetic()
                        || c.isAnonymousClass() || c.isLocalClass()) continue;
                if (!eventItf.isAssignableFrom(c)) { nonEvent.add(cn); continue; }
                eventClasses.put(cn, c);
            }
        }
        nonEvent.sort(String::compareTo);

        JsonArray arr = new JsonArray();
        for (Map.Entry<String, Class<?>> e : eventClasses.entrySet()) {
            Class<?> c = e.getValue();
            JsonObject o = new JsonObject();
            o.addProperty("className", e.getKey());
            String simple = c.getSimpleName();
            o.addProperty("shortName", simple.endsWith("Event")
                    ? simple.substring(0, simple.length() - "Event".length()) : simple);
            o.addProperty("cancellable", cancellableItf.isAssignableFrom(c));
            o.add("properties", properties(c, loadErrors));
            arr.add(o);
        }

        JsonObject root = new JsonObject();
        JsonObject meta = new JsonObject();
        meta.addProperty("generator",
                "compiler/data/GenMinestomCatalogs.java — javac -d /tmp/gencat compiler/data/GenMinestomCatalogs.java && "
              + "java -cp \"/tmp/gencat:$CP\" GenMinestomCatalogs <minestom-jar> compiler/data "
              + "(CP = runtime classpath of the :java module: pinned minestom jar + transitive deps)");
        meta.addProperty("minestomCommit", COMMIT);
        meta.addProperty("jarSha256", sha);
        meta.addProperty("scope",
                "every concrete public class under net.minestom.server.event.** that implements "
              + "net.minestom.server.event.Event; concrete public non-Event helper classes in the "
              + "package tree are listed in nonEventConcretePublicClasses and are NOT events");
        meta.addProperty("propertyRules",
                "public non-static zero-arg getters getX()/isX() from the whole hierarchy (Object "
              + "excluded, bridge/synthetic excluded, getClass excluded) plus record components; "
              + "name = snake_case of the suffix; settable = a public non-static single-arg "
              + "set<Suffix>(..) exists; javaType = generic return type");
        JsonArray ne = new JsonArray(); nonEvent.forEach(ne::add);
        JsonArray le = new JsonArray(); loadErrors.forEach(le::add);
        meta.add("nonEventConcretePublicClasses", ne);
        meta.add("loadErrors", le);
        root.add("_meta", meta);
        root.add("events", arr);
        return root;
    }

    static JsonArray properties(Class<?> c, List<String> errors) {
        // name -> [javaType, settableFlag]
        LinkedHashMap<String, JsonObject> props = new LinkedHashMap<>();
        try {
            // record components first (accessor style x(), no get prefix)
            if (c.isRecord()) {
                for (RecordComponent rc : c.getRecordComponents()) {
                    String name = snake(rc.getName());
                    JsonObject p = new JsonObject();
                    p.addProperty("name", name);
                    p.addProperty("javaType", rc.getGenericType().getTypeName());
                    p.addProperty("settable", false);
                    p.addProperty("accessor", rc.getName());
                    props.put(name, p);
                }
            }
            List<Method> methods = new ArrayList<>(List.of(c.getMethods()));
            methods.sort(Comparator.comparing(Method::getName)
                    .thenComparing(m -> m.getDeclaringClass().getName()));
            for (Method m : methods) {
                if (m.getDeclaringClass() == Object.class) continue;
                if (m.isBridge() || m.isSynthetic()) continue;
                int mod = m.getModifiers();
                if (Modifier.isStatic(mod) || !Modifier.isPublic(mod)) continue;
                if (m.getParameterCount() != 0 || m.getReturnType() == void.class) continue;
                String n = m.getName();
                String suffix;
                if (n.length() > 3 && n.startsWith("get") && Character.isUpperCase(n.charAt(3)))
                    suffix = n.substring(3);
                else if (n.length() > 2 && n.startsWith("is") && Character.isUpperCase(n.charAt(2)))
                    suffix = n.substring(2);
                else continue;
                if (n.equals("getClass")) continue;
                String name = snake(suffix);
                if (props.containsKey(name)) continue;
                boolean settable = false;
                String setterName = "set" + suffix;
                for (Method s : c.getMethods()) {
                    if (s.getName().equals(setterName) && s.getParameterCount() == 1
                            && !Modifier.isStatic(s.getModifiers()) && !s.isBridge() && !s.isSynthetic()) {
                        settable = true;
                        break;
                    }
                }
                JsonObject p = new JsonObject();
                p.addProperty("name", name);
                p.addProperty("javaType", m.getGenericReturnType().getTypeName());
                p.addProperty("settable", settable);
                p.addProperty("accessor", n);
                props.put(name, p);
            }
        } catch (Throwable t) {
            errors.add(c.getName() + " (properties) : " + t);
        }
        JsonArray out = new JsonArray();
        props.values().stream()
                .sorted(Comparator.comparing(o -> o.get("name").getAsString()))
                .forEach(out::add);
        return out;
    }

    // ================= entity-api.json =================

    static JsonObject genEntityApi(String sha) throws Exception {
        JsonObject root = new JsonObject();
        JsonObject meta = new JsonObject();
        meta.addProperty("generator",
                "compiler/data/GenMinestomCatalogs.java (same command as events.json)");
        meta.addProperty("minestomCommit", COMMIT);
        meta.addProperty("jarSha256", sha);
        root.add("_meta", meta);

        JsonObject classes = new JsonObject();
        root.add("classes", classes);

        classes.add("net.minestom.server.entity.Entity", curated(
                "net.minestom.server.entity.Entity", true,
                "getEntityType", "getUuid", "getEntityId", "getPosition", "getInstance",
                "setInstance", "teleport", "getVelocity", "setVelocity", "hasVelocity",
                "getCustomName", "setCustomName", "isCustomNameVisible", "setCustomNameVisible",
                "isGlowing", "setGlowing", "isInvisible", "setInvisible",
                "hasNoGravity", "setNoGravity", "isOnFire", "setOnFire",
                "isSilent", "setSilent",
                "getPassengers", "addPassenger", "removePassenger", "hasPassenger", "getVehicle",
                "isActive", "isRemoved", "remove",
                "getEntityMeta", "editEntityMeta", "getPose", "setPose",
                "lookAt", "getEyeHeight", "takeKnockback", "getBoundingBox", "getViewers"));

        classes.add("net.minestom.server.entity.LivingEntity", curated(
                "net.minestom.server.entity.LivingEntity", true,
                "getHealth", "setHealth", "heal", "kill", "isDead", "damage",
                "isInvulnerable", "setInvulnerable", "getFireTicks", "setFireTicks",
                "getEquipment", "setEquipment", "getAttribute", "getAttributeValue",
                "swingMainHand", "swingOffHand"));

        classes.add("net.minestom.server.entity.EntityCreature", curated(
                "net.minestom.server.entity.EntityCreature", true,
                "getTarget", "setTarget", "getNavigator", "attack", "getAIGroups", "kill"));

        classes.add("net.minestom.server.entity.EntityProjectile",
                fullDump("net.minestom.server.entity.EntityProjectile"));
        classes.add("net.minestom.server.entity.ItemEntity",
                fullDump("net.minestom.server.entity.ItemEntity"));
        classes.add("net.minestom.server.entity.metadata.other.ArmorStandMeta",
                fullDump("net.minestom.server.entity.metadata.other.ArmorStandMeta"));

        classes.add("net.minestom.server.entity.metadata.EntityMeta", curated(
                "net.minestom.server.entity.metadata.EntityMeta", false,
                "isOnFire", "setOnFire", "getCustomName", "setCustomName",
                "isCustomNameVisible", "setCustomNameVisible", "isInvisible", "setInvisible",
                "isSilent", "setSilent", "isHasNoGravity", "setHasNoGravity",
                "isHasGlowingEffect", "setHasGlowingEffect", "getPose", "setPose"));

        // supporting API needed by spawn / velocity / projectile / all_entities
        classes.add("net.minestom.server.coordinate.Pos", curated(
                "net.minestom.server.coordinate.Pos", false,
                "direction", "withDirection", "asVec", "add", "withPitch", "withYaw"));
        classes.add("net.minestom.server.coordinate.Vec", curated(
                "net.minestom.server.coordinate.Vec", false,
                "mul", "normalize", "length", "add", "x", "y", "z"));
        classes.add("net.minestom.server.instance.Instance", curated(
                "net.minestom.server.instance.Instance", false,
                "getEntities", "getNearbyEntities"));
        classes.add("net.minestom.server.instance.InstanceManager", curated(
                "net.minestom.server.instance.InstanceManager", false,
                "getInstances"));

        root.add("contract", contractTable());
        return root;
    }

    /** Contract capability -> javap-verified resolution (or the closest alternative). */
    static JsonArray contractTable() {
        JsonArray arr = new JsonArray();
        arr.add(cap("type ro", "ok",
                "net.minestom.server.entity.EntityType Entity.getEntityType()", null));
        arr.add(cap("uuid ro", "ok", "java.util.UUID Entity.getUuid()", null));
        arr.add(cap("location rw", "ok",
                "net.minestom.server.coordinate.Pos Entity.getPosition(); "
              + "java.util.concurrent.CompletableFuture<Void> Entity.teleport(Pos)", null));
        arr.add(cap("velocity rw", "ok",
                "net.minestom.server.coordinate.Vec Entity.getVelocity(); "
              + "void Entity.setVelocity(net.minestom.server.coordinate.Vec)", null));
        arr.add(cap("custom_name rw", "ok",
                "net.kyori.adventure.text.Component Entity.getCustomName(); "
              + "void Entity.setCustomName(Component)", null));
        arr.add(cap("name_visible rw", "ok",
                "boolean Entity.isCustomNameVisible(); void Entity.setCustomNameVisible(boolean)", null));
        arr.add(cap("glowing rw", "ok",
                "boolean Entity.isGlowing(); void Entity.setGlowing(boolean)", null));
        arr.add(cap("invisible rw", "ok",
                "boolean Entity.isInvisible(); void Entity.setInvisible(boolean)", null));
        arr.add(cap("gravity rw", "ok",
                "boolean Entity.hasNoGravity(); void Entity.setNoGravity(boolean)",
                "sense is inverted: gravity = !hasNoGravity(); set via setNoGravity(!value)"));
        arr.add(cap("on_fire rw", "partial",
                "boolean Entity.isOnFire() (read side only)",
                "Entity has NO public setOnFire(boolean) in this snapshot. Closest: "
              + "Entity.editEntityMeta(EntityMeta.class, m -> m.setOnFire(bool)) toggles the visual "
              + "flame flag (EntityMeta.setOnFire(boolean)); LivingEntity.setFireTicks(int) drives "
              + "actual burn ticks for living entities"));
        arr.add(cap("silent rw", "ok",
                "boolean Entity.isSilent(); void Entity.setSilent(boolean)", null));
        arr.add(cap("passengers ro", "ok",
                "java.util.Set<Entity> Entity.getPassengers()", null));
        arr.add(cap("vehicle ro", "ok",
                "Entity Entity.getVehicle()", "returns null when not riding — map to optional"));
        arr.add(cap("alive/removed", "ok",
                "boolean Entity.isRemoved(); boolean Entity.isActive(); boolean LivingEntity.isDead()",
                "Entity-level alive = !isRemoved(); isDead() only exists on LivingEntity"));
        arr.add(cap("spawn entity", "ok",
                "new Entity(EntityType) / new Entity(EntityType, UUID); "
              + "CompletableFuture<Void> Entity.setInstance(Instance, Pos|Point)", null));
        arr.add(cap("remove entity", "ok", "void Entity.remove()", null));
        arr.add(cap("mount / dismount", "ok",
                "void Entity.addPassenger(Entity); void Entity.removePassenger(Entity); "
              + "boolean Entity.hasPassenger(); Entity Entity.getVehicle()", null));
        arr.add(cap("launch projectile", "ok",
                "new EntityProjectile(Entity shooter, EntityType); "
              + "void EntityProjectile.shoot(net.minestom.server.coordinate.Point to, double power, double spread); "
              + "Entity EntityProjectile.getShooter()",
                "shoot() aims at a target Point (not a velocity): spawn at shooter eye pos "
              + "(getPosition().add(0, getEyeHeight(), 0)), then shoot(eyePos.add(position.direction()), "
              + "speed, spread). There is no shoot(from,to,...) or shootFrom overload in this snapshot; "
              + "an explicit `with velocity <v>` maps to Entity.setVelocity(Vec) after spawn instead"));
        arr.add(cap("all_entities([type])", "ok",
                "java.util.Set<Entity> Instance.getEntities(); "
              + "java.util.Set<Instance> InstanceManager.getInstances()",
                "aggregate over MinecraftServer.getInstanceManager().getInstances(); filter by "
              + "getEntityType() for the optional type argument"));
        arr.add(cap("item entity", "ok",
                "new ItemEntity(ItemStack); ItemStack ItemEntity.getItemStack(); "
              + "void ItemEntity.setItemStack(ItemStack); void ItemEntity.setPickupDelay(java.time.Duration)", null));
        arr.add(cap("armor stand", "ok",
                "spawn Entity(EntityType.ARMOR_STAND) then editEntityMeta(ArmorStandMeta.class, ...): "
              + "setSmall/setHasArms/setHasNoBasePlate/setMarker/setHeadRotation(Vec)/... (see class dump)",
                "no dedicated ArmorStand entity class — it is Entity + ArmorStandMeta"));
        arr.add(cap("display IS-A entity", "ok",
                "display/hologram entities are plain Entity instances with Display*Meta — mount/teleport "
              + "unification holds with no extra API", null));
        return arr;
    }

    static JsonObject cap(String capability, String status, String resolved, String note) {
        JsonObject o = new JsonObject();
        o.addProperty("capability", capability);
        o.addProperty("status", status);
        o.addProperty("resolved", resolved);
        if (note != null) o.addProperty("note", note);
        return o;
    }

    /** Curated lookup: exact signatures of the named methods anywhere in the hierarchy. */
    static JsonObject curated(String className, boolean withCtors, String... names) throws Exception {
        Class<?> c = Class.forName(className, false, GenMinestomCatalogs.class.getClassLoader());
        JsonObject o = new JsonObject();
        if (withCtors) o.add("constructors", ctors(c));
        JsonObject methods = new JsonObject();
        List<String> missing = new ArrayList<>();
        TreeMap<String, JsonArray> byName = new TreeMap<>();
        for (String name : names) {
            JsonArray sigs = new JsonArray();
            List<Method> found = new ArrayList<>();
            for (Method m : c.getMethods()) {
                if (!m.getName().equals(name) || m.isBridge() || m.isSynthetic()) continue;
                found.add(m);
            }
            found.sort(Comparator.comparing(GenMinestomCatalogs::sig));
            for (Method m : found) sigs.add(methodObj(m));
            if (found.isEmpty()) missing.add(name);
            else byName.put(name, sigs);
        }
        byName.forEach(methods::add);
        o.add("methods", methods);
        if (!missing.isEmpty()) {
            JsonArray ma = new JsonArray();
            missing.forEach(ma::add);
            o.add("missingLookups", ma);
        }
        return o;
    }

    /** Full dump: all public constructors + all public declared methods of the class itself. */
    static JsonObject fullDump(String className) throws Exception {
        Class<?> c = Class.forName(className, false, GenMinestomCatalogs.class.getClassLoader());
        JsonObject o = new JsonObject();
        o.addProperty("superclass", c.getSuperclass() == null ? null : c.getSuperclass().getName());
        o.add("constructors", ctors(c));
        List<Method> ms = new ArrayList<>();
        for (Method m : c.getDeclaredMethods()) {
            if (!Modifier.isPublic(m.getModifiers()) || m.isBridge() || m.isSynthetic()) continue;
            ms.add(m);
        }
        ms.sort(Comparator.comparing(Method::getName).thenComparing(GenMinestomCatalogs::sig));
        JsonArray arr = new JsonArray();
        for (Method m : ms) arr.add(methodObj(m));
        o.add("declaredPublicMethods", arr);
        return o;
    }

    static JsonArray ctors(Class<?> c) {
        List<Constructor<?>> cs = new ArrayList<>(List.of(c.getConstructors()));
        cs.sort(Comparator.comparing(GenMinestomCatalogs::ctorSig));
        JsonArray arr = new JsonArray();
        for (Constructor<?> k : cs) {
            JsonObject o = new JsonObject();
            JsonArray params = new JsonArray();
            for (var t : k.getGenericParameterTypes()) params.add(t.getTypeName());
            o.add("params", params);
            o.addProperty("signature", ctorSig(k));
            arr.add(o);
        }
        return arr;
    }

    static JsonObject methodObj(Method m) {
        JsonObject o = new JsonObject();
        o.addProperty("declaredIn", m.getDeclaringClass().getName());
        o.addProperty("static", Modifier.isStatic(m.getModifiers()));
        o.addProperty("returns", m.getGenericReturnType().getTypeName());
        JsonArray params = new JsonArray();
        for (var t : m.getGenericParameterTypes()) params.add(t.getTypeName());
        o.add("params", params);
        o.addProperty("signature", sig(m));
        return o;
    }

    static String sig(Method m) {
        StringBuilder sb = new StringBuilder();
        sb.append(m.getGenericReturnType().getTypeName()).append(' ').append(m.getName()).append('(');
        var ps = m.getGenericParameterTypes();
        for (int i = 0; i < ps.length; i++) {
            if (i > 0) sb.append(", ");
            sb.append(ps[i].getTypeName());
        }
        return sb.append(')').toString();
    }

    static String ctorSig(Constructor<?> k) {
        StringBuilder sb = new StringBuilder();
        sb.append(k.getDeclaringClass().getSimpleName()).append('(');
        var ps = k.getGenericParameterTypes();
        for (int i = 0; i < ps.length; i++) {
            if (i > 0) sb.append(", ");
            sb.append(ps[i].getTypeName());
        }
        return sb.append(')').toString();
    }

    // ================= events_data.ml =================

    static void writeOcamlFragment(Path out, JsonObject events) throws Exception {
        StringBuilder sb = new StringBuilder();
        sb.append("(* GENERATED from events.json (source of truth) by compiler/data/GenMinestomCatalogs.java\n");
        sb.append("   — see the header of that file for the regeneration command. Do not edit by hand.\n");
        sb.append("   Minestom ").append(COMMIT).append(". *)\n\n");
        sb.append("type gen_event_prop = {\n");
        sb.append("  p_name : string;        (* snake_case property name *)\n");
        sb.append("  p_java_type : string;   (* generic Java type of the getter *)\n");
        sb.append("  p_settable : bool;      (* a matching public setter exists *)\n");
        sb.append("  p_accessor : string;    (* Java accessor method name *)\n");
        sb.append("}\n\n");
        sb.append("type gen_event = {\n");
        sb.append("  ev_class : string;       (* fully-qualified Java class *)\n");
        sb.append("  ev_short : string;       (* class name minus trailing \"Event\" *)\n");
        sb.append("  ev_cancellable : bool;\n");
        sb.append("  ev_props : gen_event_prop list;\n");
        sb.append("}\n\n");
        sb.append("let generated_events : gen_event list = [\n");
        for (var e : events.getAsJsonArray("events")) {
            JsonObject o = e.getAsJsonObject();
            sb.append("  { ev_class = \"").append(o.get("className").getAsString()).append("\";\n");
            sb.append("    ev_short = \"").append(o.get("shortName").getAsString()).append("\";\n");
            sb.append("    ev_cancellable = ").append(o.get("cancellable").getAsBoolean()).append(";\n");
            sb.append("    ev_props = [");
            JsonArray props = o.getAsJsonArray("properties");
            for (int i = 0; i < props.size(); i++) {
                JsonObject p = props.get(i).getAsJsonObject();
                if (i > 0) sb.append(";");
                sb.append("\n      { p_name = \"").append(p.get("name").getAsString());
                sb.append("\"; p_java_type = \"").append(p.get("javaType").getAsString().replace("\\", "\\\\").replace("\"", "\\\""));
                sb.append("\"; p_settable = ").append(p.get("settable").getAsBoolean());
                sb.append("; p_accessor = \"").append(p.get("accessor").getAsString()).append("\" }");
            }
            if (props.size() > 0) sb.append("\n    ");
            sb.append("] };\n");
        }
        sb.append("]\n");
        Files.writeString(out, sb.toString());
    }

    // ================= util =================

    static String snake(String s) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            char ch = s.charAt(i);
            if (Character.isUpperCase(ch)) {
                boolean prevLower = i > 0
                        && (Character.isLowerCase(s.charAt(i - 1)) || Character.isDigit(s.charAt(i - 1)));
                boolean nextLower = i + 1 < s.length() && Character.isLowerCase(s.charAt(i + 1));
                if (sb.length() > 0 && (prevLower || nextLower) && sb.charAt(sb.length() - 1) != '_')
                    sb.append('_');
                sb.append(Character.toLowerCase(ch));
            } else {
                sb.append(ch);
            }
        }
        return sb.toString();
    }

    static String sha256(String path) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] h = md.digest(Files.readAllBytes(Path.of(path)));
        StringBuilder sb = new StringBuilder();
        for (byte b : h) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    static void write(Path p, JsonObject o) throws Exception {
        try (Writer w = new FileWriter(p.toFile())) {
            GSON.toJson(o, w);
            w.write('\n');
        }
    }
}
