package net.swofty.model;

import net.swofty.nativebridge.execution.Expression;

/**
 * Tablist entry skin: builtin palette name, a player expression, or a
 * custom texture/signature pair
 */
public record SkinSpecModel(
        Kind kind,
        String builtinName,
        Expression playerExpr,
        Expression texture,
        Expression signature) {

    public enum Kind {
        BUILTIN,
        PLAYER,
        CUSTOM
    }

    public static SkinSpecModel builtin(String name) {
        return new SkinSpecModel(Kind.BUILTIN, name, null, null, null);
    }

    public static SkinSpecModel player(Expression expr) {
        return new SkinSpecModel(Kind.PLAYER, null, expr, null, null);
    }

    public static SkinSpecModel custom(Expression texture, Expression signature) {
        return new SkinSpecModel(Kind.CUSTOM, null, null, texture, signature);
    }
}
