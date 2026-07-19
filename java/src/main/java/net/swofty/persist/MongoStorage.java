package net.swofty.persist;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.google.gson.JsonElement;
import com.mongodb.ConnectionString;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.model.Filters;
import com.mongodb.client.model.IndexOptions;
import com.mongodb.client.model.Indexes;
import com.mongodb.client.model.ReplaceOneModel;
import com.mongodb.client.model.ReplaceOptions;
import com.mongodb.client.model.WriteModel;

import org.bson.Document;

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

    @Override
    public void close() {
        client.close();
    }
}
