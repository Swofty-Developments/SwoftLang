package net.swofty.nativebridge.execution.commands.npcs;

import net.minestom.server.entity.PlayerSkin;
import net.swofty.model.NpcModel.NpcSkinModel;
import net.swofty.nativebridge.execution.AbstractAstNode;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.npcs.NpcRuntime;
import net.swofty.props.Coercions;
import net.swofty.runtime.ExecutionContext;

/**
 * {@code set npc "name" skin <username|skin(texture, signature)>} (GROUP C).
 * A username is passed as a String for an async Mojang fetch; a texture pair
 * becomes a {@link PlayerSkin} applied immediately.
 */
public class SetNpcSkinStatement extends AbstractAstNode implements Statement {
    private final String name;
    private final NpcSkinModel skin;

    public SetNpcSkinStatement(String name, NpcSkinModel skin) {
        this.name = name;
        this.skin = skin;
    }

    @Override
    public void execute(ExecutionContext context) {
        if (skin.kind() == NpcSkinModel.Kind.TEXTURE) {
            String texture = String.valueOf(Coercions.toStringValue(context.evaluate(skin.texture())));
            String signature = skin.signature() == null ? null
                    : String.valueOf(Coercions.toStringValue(context.evaluate(skin.signature())));
            NpcRuntime.setSkin(name, new PlayerSkin(texture, signature));
        } else {
            NpcRuntime.setSkin(name,
                    String.valueOf(Coercions.toStringValue(context.evaluate(skin.username()))));
        }
    }
}
