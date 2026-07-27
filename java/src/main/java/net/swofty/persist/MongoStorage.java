package net.swofty.persist;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.google.gson.JsonElement;
import com.mongodb.ConnectionString;
import com.mongodb.MongoWriteException;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Indexes;
import com.mongodb.client.model.ReplaceOneModel;
import com.mongodb.client.model.ReplaceOptions;
import com.mongodb.client.model.UpdateOptions;
import com.mongodb.client.model.Updates;
import com.mongodb.client.model.WriteModel;
import com.mongodb.client.result.UpdateResult;

import org.bson.Document;
import org.bson.conversions.Bson;

/**
 * MongoDB backend (org.mongodb:mongodb-driver-sync): one collection
 * "swoft_persist" of {var, key, value} documents where value is the
 * scalar's JSON text, keeping coercion identical across backends. The
 * database comes from the connection string (default "swoftlang").
 */
public final class MongoStorage implements SwoftStorage {
    private final MongoClient client;
    private final MongoCollection<Document> collection;

    public MongoStorage(String uri) {
        ConnectionString connectionString = new ConnectionString(uri);
        client = MongoClients.create(connectionString);
        String database = connectionString.getDatabase() != null
                ? connectionString.getDatabase() : "swoftlang";
        collection = client.getDatabase(database).getCollection("swoft_persist");
        collection.createIndex(Indexes.ascending("var", "key"),
                new IndexOptions().unique(true));
    }

    @Override
    public Map<String, JsonElement> loadAll(String var) {
        Map<String, JsonElement> rows = new LinkedHashMap<>();
        for (Document doc : collection.find(Filters.eq("var", var))) {
            PersistStore.putParsedRow(rows, var,
                    doc.getString("key"), doc.getString("value"));
        }
        return rows;
    }

    @Override
    public JsonElement load(String var, String key) {
        Map<String, JsonElement> rows = new LinkedHashMap<>();
        Document doc = collection.find(
                Filters.and(Filters.eq("var", var), Filters.eq("key", key))).first();
        if (doc != null) {
            PersistStore.putParsedRow(rows, var, doc.getString("key"), doc.getString("value"));
        }
        return rows.get(key);
    }

    @Override
    public void writeBatch(String var, Map<String, JsonElement> dirty) {
        List<WriteModel<Document>> operations = new ArrayList<>(dirty.size());
        for (Map.Entry<String, JsonElement> entry : dirty.entrySet()) {
            Document document = new Document("var", var)
                    .append("key", entry.getKey())
                    .append("value", entry.getValue().toString());
            operations.add(new ReplaceOneModel<>(
                    Filters.and(Filters.eq("var", var), Filters.eq("key", entry.getKey())),
                    document, new ReplaceOptions().upsert(true)));
        }
        if (!operations.isEmpty()) {
            collection.bulkWrite(operations);
        }
    }

    /**
     * The real conditional write (1.10.0 §2.1/§2.2). The unique index on
     * {@code (var, key)} makes each branch a single-document atomic operation:
     * the guarded update matches only if the stored text is still what we read,
     * and the guarded upsert can be won by exactly one racer (the losers either
     * fail to match or take a duplicate-key error).
     */
    @Override
    public CasOutcome compareAndSet(String var, String key, String expected, String next) {
        String stored = next == null ? "null" : next;
        Bson row = Filters.and(Filters.eq("var", var), Filters.eq("key", key));
        if (expected != null) {
            UpdateResult result = collection.updateOne(
                    Filters.and(row, Filters.eq("value", expected)),
                    Updates.set("value", stored));
            if (result.getMatchedCount() == 1) {
                return new CasOutcome(true, next);
            }
            return new CasOutcome(false, readRaw(row));
        }
        // expected == null: claim a row that is absent or holds the tombstone.
        try {
            UpdateResult result = collection.updateOne(
                    Filters.and(row, Filters.or(Filters.exists("value", false),
                            Filters.eq("value", "null"))),
                    Updates.set("value", stored),
                    new UpdateOptions().upsert(true));
            if (result.getMatchedCount() == 1 || result.getUpsertedId() != null) {
                return new CasOutcome(true, next);
            }
        } catch (MongoWriteException e) {
            // another racer inserted the document first; fall through and report
            // what they wrote
        }
        return new CasOutcome(false, readRaw(row));
    }

    /** The row exactly as stored, or null when absent / tombstoned. */
    private String readRaw(Bson row) {
        Document doc = collection.find(row).first();
        String value = doc == null ? null : doc.getString("value");
        return "null".equals(value) ? null : value;
    }

    @Override
    public void close() {
        client.close();
    }
}
