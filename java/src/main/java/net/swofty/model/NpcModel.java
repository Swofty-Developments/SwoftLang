package net.swofty.model;

import java.util.Map;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * npc "name" { ... } declaration (design 6C, first-class). A fake player
 * entity spawned in-world (never a real connection, so it never leaks into
 * command tab-completion), rendered per viewer via a PlayerInfoUpdate ADD +
 * spawn packet with the tablist entry removed shortly after so it shows in
 * the world but not the player list.
 *
 * <ul>
 *   <li>{@code location} — required base position expression.</li>
 *   <li>{@code displayName} — nullable overhead name expression
 *       (MiniMessage, per-viewer capable when it interpolates a
 *       player-scoped path).</li>
 *   <li>{@code skin} — nullable; a username (Mojang-fetched, async) or a
 *       texture/signature pair.</li>
 *   <li>{@code lookAtPlayers} — head tracks the nearest player when true.</li>
 *   <li>{@code onClick} / {@code onLeftClick} — nullable handler bodies run
 *       through an ASTExecutor with {@code player} bound.</li>
 * </ul>
 */
public record NpcModel(
        String name,
        Expression location,
        Expression displayName,
        NpcSkinModel skin,
        boolean lookAtPlayers,
        ExecuteBlock onClick,
        ExecuteBlock onLeftClick,
        Map<String, InlineHandler> handlers) {

    /** Pre-inline-handlers shape, kept for existing call sites/smoke tests. */
    public NpcModel(String name, Expression location, Expression displayName,
            NpcSkinModel skin, boolean lookAtPlayers, ExecuteBlock onClick,
            ExecuteBlock onLeftClick) {
        this(name, location, displayName, skin, lookAtPlayers, onClick,
                onLeftClick, Map.of());
    }

    /** The generic first-class handler for {@code event}, or null. */
    public InlineHandler handler(String event) {
        return handlers == null ? null : handlers.get(event);
    }

    /**
     * npc skin spec: a player username (fetched from Mojang) or a raw
     * base64 texture value + signature pair.
     */
    public record NpcSkinModel(
            Kind kind,
            Expression username,
            Expression texture,
            Expression signature) {

        public enum Kind {
            USERNAME,
            TEXTURE
        }

        public static NpcSkinModel username(Expression username) {
            return new NpcSkinModel(Kind.USERNAME, username, null, null);
        }

        public static NpcSkinModel texture(Expression texture, Expression signature) {
            return new NpcSkinModel(Kind.TEXTURE, null, texture, signature);
        }
    }
}
