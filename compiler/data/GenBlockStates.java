// GenBlockStates — generates compiler/data/block_states.json from the pinned
// Minestom jar by reflecting over the Block registry. Modeled on
// GenMinestomCatalogs.java (same determinism / regeneration discipline).
//
// Output shape:
//   {
//     "_meta": { generator, minestomCommit, jarSha256, blockCount,
//                blockEntityBlockCount, blockEntityTypeCount },
//     "blocks": { "<namespaced id>": { "<property>": [allowed values...], ... }, ... },
//     "block_entity_ids": { "<namespaced block id>": "<block-entity key>", ... },
//     "block_entity_types": [ "<block-entity-type key>", ... ]
//   }
//
// Block ids are the full namespaced key (Key.asString(), e.g. "minecraft:oak_stairs")
// — matches the runtime's canonical form (SetBlockStatement normalizes bare ids to
// "minecraft:<name>" before Block.fromKey). Property value lists are deterministically
// sorted (numeric-aware, so age=[0..15] not [0,1,10,...]). No single Minestom API
// returns allowed values per property, so they are enumerated from possibleStates().
//
// Regenerate with (CP = full runtime classpath of the :java gradle module):
//   nix-shell -p jdk25 --run "
//     javac -d /tmp/genbs compiler/data/GenBlockStates.java &&
//     java -cp /tmp/genbs:$CP GenBlockStates <minestom-jar> compiler/data"
// (JDK 25 — the pinned jar is Java-25 bytecode.)

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.io.FileWriter;
import java.io.Writer;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Collection;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

public final class GenBlockStates {

    static final String COMMIT = "2026.07.12-26.2";
    static final Gson GSON = new GsonBuilder().setPrettyPrinting().disableHtmlEscaping().create();

    @SuppressWarnings("unchecked")
    public static void main(String[] args) throws Exception {
        String jarPath = args[0];
        Path outDir = Path.of(args[1]);
        Files.createDirectories(outDir);
        String sha = sha256(jarPath);

        Class<?> blockItf = Class.forName("net.minestom.server.instance.block.Block");
        Method mValues = blockItf.getMethod("values");
        Method mKey = blockItf.getMethod("key");
        Method mDefaultState = blockItf.getMethod("defaultState");
        Method mProperties = blockItf.getMethod("properties");
        Method mPossibleStates = blockItf.getMethod("possibleStates");
        Method mGetProperty = blockItf.getMethod("getProperty", String.class);
        Method mRegistry = blockItf.getMethod("registry");

        Class<?> entryCls = Class.forName("net.minestom.server.registry.RegistryData$BlockEntry");
        Method mIsBlockEntity = entryCls.getMethod("isBlockEntity");
        Method mBlockEntity = entryCls.getMethod("blockEntity"); // adventure Key, may be null

        Class<?> keyCls = Class.forName("net.kyori.adventure.key.Key");
        Method mAsString = keyCls.getMethod("asString");

        // blockId -> (property -> sorted value set)
        TreeMap<String, TreeMap<String, JsonArray>> blocks = new TreeMap<>();
        // blockId -> block-entity key string
        TreeMap<String, String> blockEntityIds = new TreeMap<>();

        Collection<Object> all = (Collection<Object>) mValues.invoke(null);
        int blockCount = 0;
        for (Object block : all) {
            blockCount++;
            String id = (String) mAsString.invoke(mKey.invoke(block));

            // Property KEYS come from the default state's key set; ALLOWED VALUES are the
            // distinct getProperty(key) across every state permutation of this block.
            Object def = mDefaultState.invoke(block);
            @SuppressWarnings("unchecked")
            java.util.Map<String, String> defProps =
                    (java.util.Map<String, String>) mProperties.invoke(def);

            TreeMap<String, JsonArray> propTable = new TreeMap<>();
            if (!defProps.isEmpty()) {
                // key -> distinct values
                java.util.LinkedHashMap<String, Set<String>> collected = new java.util.LinkedHashMap<>();
                for (String key : defProps.keySet()) collected.put(key, new LinkedHashSet<>());
                @SuppressWarnings("unchecked")
                Collection<Object> states = (Collection<Object>) mPossibleStates.invoke(block);
                for (Object st : states) {
                    for (String key : collected.keySet()) {
                        collected.get(key).add((String) mGetProperty.invoke(st, key));
                    }
                }
                for (var e : collected.entrySet()) {
                    JsonArray arr = new JsonArray();
                    TreeSet<String> sorted = new TreeSet<>(VALUE_ORDER);
                    sorted.addAll(e.getValue());
                    sorted.forEach(arr::add);
                    propTable.put(e.getKey(), arr);
                }
            }
            blocks.put(id, propTable);

            // block-entity id, if this block carries one
            Object entry = mRegistry.invoke(block);
            if (entry != null && (boolean) mIsBlockEntity.invoke(entry)) {
                Object beKey = mBlockEntity.invoke(entry);
                if (beKey != null) {
                    blockEntityIds.put(id, (String) mAsString.invoke(beKey));
                }
            }
        }

        // BlockEntityType registry ids
        Class<?> betCls = Class.forName("net.minestom.server.instance.block.BlockEntityType");
        Method betValues = betCls.getMethod("values");
        Method betKey = betCls.getMethod("key");
        @SuppressWarnings("unchecked")
        Collection<Object> bets = (Collection<Object>) betValues.invoke(null);
        TreeSet<String> betIds = new TreeSet<>();
        for (Object bet : bets) betIds.add((String) mAsString.invoke(betKey.invoke(bet)));

        // ---- assemble JSON ----
        JsonObject root = new JsonObject();
        JsonObject meta = new JsonObject();
        meta.addProperty("generator",
                "compiler/data/GenBlockStates.java — nix-shell -p jdk25 --run \"javac -d /tmp/genbs "
              + "compiler/data/GenBlockStates.java && java -cp /tmp/genbs:$CP GenBlockStates "
              + "<minestom-jar> compiler/data\" (CP = runtime classpath of the :java module)");
        meta.addProperty("minestomCommit", COMMIT);
        meta.addProperty("jarSha256", sha);
        meta.addProperty("scope",
                "every Block in Block.values(); keys are the full namespaced id (Key.asString()); "
              + "per property the allowed values are enumerated from possibleStates() and sorted "
              + "numeric-aware; block_entity_ids maps blocks whose RegistryData.BlockEntry.isBlockEntity() "
              + "to their block-entity key; block_entity_types is the BlockEntityType registry");
        meta.addProperty("blockCount", blockCount);
        meta.addProperty("blockEntityBlockCount", blockEntityIds.size());
        meta.addProperty("blockEntityTypeCount", betIds.size());
        root.add("_meta", meta);

        JsonObject blocksObj = new JsonObject();
        for (var be : blocks.entrySet()) {
            JsonObject props = new JsonObject();
            be.getValue().forEach(props::add);
            blocksObj.add(be.getKey(), props);
        }
        root.add("blocks", blocksObj);

        JsonObject beObj = new JsonObject();
        blockEntityIds.forEach(beObj::addProperty);
        root.add("block_entity_ids", beObj);

        JsonArray betArr = new JsonArray();
        betIds.forEach(betArr::add);
        root.add("block_entity_types", betArr);

        write(outDir.resolve("block_states.json"), root);

        System.out.println("blocks=" + blockCount);
        System.out.println("blocksWithProps=" + blocks.values().stream().filter(m -> !m.isEmpty()).count());
        System.out.println("blockEntityBlocks=" + blockEntityIds.size());
        System.out.println("blockEntityTypes=" + betIds.size());
    }

    /** Numeric-aware value ordering: all-numeric values sort numerically, else lexicographically. */
    static final Comparator<String> VALUE_ORDER = (a, b) -> {
        boolean na = isInt(a), nb = isInt(b);
        if (na && nb) {
            int c = Long.compare(Long.parseLong(a), Long.parseLong(b));
            if (c != 0) return c;
        }
        return a.compareTo(b);
    };

    static boolean isInt(String s) {
        if (s.isEmpty()) return false;
        for (int i = 0; i < s.length(); i++) if (!Character.isDigit(s.charAt(i))) return false;
        return true;
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
