package net.swofty.persist;

import java.io.IOException;
import java.nio.file.AtomicMoveNotSupportedException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

/**
 * One JSON file per persistent variable under a directory; each file is a
 * flat object of key to scalar value. Writes go to a .tmp sibling first
 * and are moved into place atomically so a crash never truncates data.
 */
public final class FilesStorage implements SwoftStorage {
    private final Path directory;

    /** Full var file contents, so batch writes only rewrite dirty keys. */
    private final Map<String, JsonObject> mirror = new HashMap<>();

    public FilesStorage(String directory) {
        this.directory = Path.of(directory);
        try {
            Files.createDirectories(this.directory);
        } catch (IOException e) {
            throw new RuntimeException("cannot create persistence directory "
                    + this.directory + ": " + e.getMessage(), e);
        }
    }

    @Override
    public synchronized Map<String, JsonElement> loadAll(String var) {
        JsonObject contents = readFile(var);
        mirror.put(var, contents);
        Map<String, JsonElement> rows = new LinkedHashMap<>();
        for (Map.Entry<String, JsonElement> entry : contents.entrySet()) {
            rows.put(entry.getKey(), entry.getValue());
        }
        return rows;
    }

    @Override
    public synchronized void writeBatch(String var, Map<String, JsonElement> dirty) {
        JsonObject contents = mirror.computeIfAbsent(var, this::readFile);
        for (Map.Entry<String, JsonElement> entry : dirty.entrySet()) {
            contents.add(entry.getKey(), entry.getValue());
        }

        Path file = fileFor(var);
        Path tmp = directory.resolve(var + ".json.tmp");
        try {
            Files.writeString(tmp, contents.toString());
            try {
                Files.move(tmp, file, StandardCopyOption.REPLACE_EXISTING,
                        StandardCopyOption.ATOMIC_MOVE);
            } catch (AtomicMoveNotSupportedException e) {
                Files.move(tmp, file, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            throw new RuntimeException("cannot write " + file + ": " + e.getMessage(), e);
        }
    }

    @Override
    public void close() {
        // nothing to release
    }

    private Path fileFor(String var) {
        return directory.resolve(var + ".json");
    }

    private JsonObject readFile(String var) {
        Path file = fileFor(var);
        if (!Files.isRegularFile(file)) {
            return new JsonObject();
        }
        try {
            return JsonParser.parseString(Files.readString(file)).getAsJsonObject();
        } catch (Exception e) {
            System.err.println("Warning: corrupt persistence file " + file
                    + " (" + e.getMessage() + ") - starting empty");
            return new JsonObject();
        }
    }
}
