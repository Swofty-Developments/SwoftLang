package net.swofty.persist;

import java.util.Map;

import com.google.gson.JsonElement;

/**
 * Backend for persistent variables. Values are scalar JSON elements; the
 * key "" addresses the global scalar of a var, any other key is a subject
 * key (Player subjects use uuid.toString()). Implementations are only
 * touched by the PersistStore flush thread plus init/shutdown, but must
 * tolerate being called from either.
 */
public interface SwoftStorage {

    /**
     * Load every stored row of one persistent variable.
     * @param var the persistent variable name
     * @return key to scalar JSON value; empty when nothing is stored
     */
    Map<String, JsonElement> loadAll(String var);

    /**
     * Write the given dirty rows of one persistent variable. Rows absent
     * from the map keep their stored value.
     */
    void writeBatch(String var, Map<String, JsonElement> dirty);

    /**
     * Release the backend (close connections / clients).
     */
    void close();
}
