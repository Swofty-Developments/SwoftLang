package net.swofty.permissions;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;

/**
 * server { permissions { "user": ["perm", ...] } } provider (design
 * 6D): username (case-insensitive) or "*" (everyone) to permission
 * lists. Nodes support "*" (all) and trailing-wildcard prefixes
 * ("admin.*"). The console always passes.
 */
public final class MapPermissionProvider implements PermissionProvider {
    private final Map<String, List<String>> byUser = new TreeMap<>();

    public MapPermissionProvider(Map<String, List<String>> permissions) {
        if (permissions != null) {
            for (Map.Entry<String, List<String>> entry : permissions.entrySet()) {
                byUser.put(entry.getKey().toLowerCase(Locale.ROOT), List.copyOf(entry.getValue()));
            }
        }
    }

    @Override
    public boolean hasPermission(CommandSender sender, String permission) {
        if (!(sender instanceof Player player)) {
            return true; // console
        }
        return grants(byUser.get(player.getUsername().toLowerCase(Locale.ROOT)), permission)
                || grants(byUser.get("*"), permission);
    }

    private static boolean grants(List<String> nodes, String permission) {
        if (nodes == null) {
            return false;
        }
        for (String node : nodes) {
            if (node.equals("*") || node.equalsIgnoreCase(permission)) {
                return true;
            }
            if (node.endsWith(".*") && permission.toLowerCase(Locale.ROOT)
                    .startsWith(node.substring(0, node.length() - 1).toLowerCase(Locale.ROOT))) {
                return true;
            }
        }
        return false;
    }
}
