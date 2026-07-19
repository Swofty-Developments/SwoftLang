package net.swofty.model;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * One on packet "ClientXxxPacket" { } declaration (design 5D). The name is
 * a short or fully-qualified client packet class name, resolved at
 * registration against net.minestom.server.network.packet.client.**.
 */
public record PacketHandlerModel(String name, ExecuteBlock execute, int line, int col) {
}
