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
     * Load ONE stored row, or null when it is absent (1.10.0 §2: a network-mode
     * join loads exactly the joining player's rows, and a replicated global's
     * atomic write re-reads exactly the row it is about to modify — neither can
     * afford {@link #loadAll} over every player of every variable).
     *
     * <p>The default is the correct-but-slow fallback; the SQL/Mongo backends
     * override it with a single-row query. Never called on the standalone path,
     * so standalone behaviour is untouched.
     */
    default JsonElement load(String var, String key) {
        return loadAll(var).get(key);
    }

    /**
     * Write the given dirty rows of one persistent variable. Rows absent
     * from the map keep their stored value.
     */
    void writeBatch(String var, Map<String, JsonElement> dirty);

    /**
     * The result of a {@link #compareAndSet}: whether the swap happened, and
     * what was actually stored when it did not.
     *
     * @param swapped  true when {@code next} is now the stored text
     * @param observed the text the row really holds; null means "no row"
     */
    record CasOutcome(boolean swapped, String observed) {
    }

    /**
     * Atomically replace the STORED TEXT of one row, but only if it still reads
     * exactly {@code expected} (1.10.0 §2.1/§2.2).
     *
     * <p><b>Why the backend needs this at all.</b> Every multi-server guarantee
     * in {@code mode: network} reduces to one question the backend has to be able
     * to answer: <em>did anyone change this row since I read it?</em> Without it,
     * "read, check, write, read back" is a TOCTOU — two servers both read a free
     * lease, both write, and both read back their own write because the second
     * one landed after the first one checked. That grants ONE player to TWO
     * servers, which is the §0 desync with no guard left downstream. The same
     * hole makes {@code add 50 to pot} lose updates. One conditional write closes
     * both.
     *
     * <p>Compared on the stored TEXT rather than on a parsed value, because that
     * is what every backend actually holds and it is what SQL and Mongo can
     * compare inside the write. A caller that re-serialized its expectation
     * slightly differently simply loses the race once and retries with the
     * {@link CasOutcome#observed} text, so the comparison is allowed to be strict.
     *
     * @param var      persistent variable name
     * @param key      row key
     * @param expected the text the row must currently hold; null means the row
     *                 must be ABSENT (a stored JSON {@code null} counts as absent,
     *                 since that is how a deletion is recorded)
     * @param next     the text to store; null deletes the row (recorded as a
     *                 stored JSON {@code null} on backends without a row delete)
     */
    default CasOutcome compareAndSet(String var, String key, String expected, String next) {
        // The single-process fallback: correct for files/sqlite, which is all it
        // has to be, since 'mode: network' on those backends is a compile error.
        synchronized (this) {
            JsonElement current = load(var, key);
            String observed = current == null || current.isJsonNull() ? null : current.toString();
            if (!java.util.Objects.equals(observed, expected)) {
                return new CasOutcome(false, observed);
            }
            writeBatch(var, Map.of(key, next == null
                    ? com.google.gson.JsonNull.INSTANCE
                    : com.google.gson.JsonParser.parseString(next)));
            return new CasOutcome(true, next);
        }
    }

    /**
     * Release the backend (close connections / clients).
     */
    void close();
}
