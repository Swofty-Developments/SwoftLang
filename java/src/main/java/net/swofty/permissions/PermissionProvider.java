package net.swofty.permissions;

import net.minestom.server.command.CommandSender;

/**
 * Pluggable permission backend (design 6D): the pinned Minestom has no
 * permission API, so command enforcement and has_permission() go
 * through this interface. Host servers replace the default via
 * {@link Permissions#setProvider}.
 */
public interface PermissionProvider {

    /**
     * @param sender     the command sender (player or console)
     * @param permission the permission node, e.g. "admin.heal"
     * @return whether the sender holds the permission
     */
    boolean hasPermission(CommandSender sender, String permission);
}
