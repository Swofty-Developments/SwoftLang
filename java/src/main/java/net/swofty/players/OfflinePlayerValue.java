package net.swofty.players;

/**
 * Script-facing OfflinePlayer identity (phase 8): a uuid plus the last
 * known name. Player values are treated as OfflinePlayer by the type
 * system (Player &lt;: OfflinePlayer); this record carries the pure-offline
 * form. Property rows live in {@link OfflinePlayerProperties}; the live
 * bridge is the 'player' row (optional&lt;Player&gt; via ConnectionManager).
 */
public record OfflinePlayerValue(String uuid, String name) {
}
