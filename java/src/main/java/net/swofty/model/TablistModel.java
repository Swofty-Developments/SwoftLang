package net.swofty.model;

import java.util.List;

import net.swofty.nativebridge.execution.Expression;

public record TablistModel(
        String name,
        UpdateCadence update,
        Expression header,
        Expression footer,
        List<TablistColumnModel> columns) {
}
