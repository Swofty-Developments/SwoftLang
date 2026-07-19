package net.swofty.model;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * column { ... } — restricted statement list (entry/fill/if/loop), up to 20
 * entries per column
 */
public record TablistColumnModel(ExecuteBlock body) {
}
