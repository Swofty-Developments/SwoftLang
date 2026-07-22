package net.swofty.model;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One {@code migrate to N { ... }} block of a persistent struct declaration
 * (§ schema migration, Tier 2). {@code toVersion} is the schema version this
 * block upgrades TO; {@code body} is the statement block run when a stored row
 * is older than {@code toVersion}. The block runs through the normal statement
 * runtime with the raw prior fields bound (each as a bare variable and under a
 * {@code raw} map), and assigns the updated new-shape fields ({@code set name to
 * ...}). Blocks run in ascending {@code toVersion} order, from stored_version+1
 * up to the struct's current {@code schema}.
 */
public record MigrateBlockModel(
        int toVersion,
        ExecuteBlock body,
        int line,
        int col) {
}
