package net.swofty.permissions;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;

/**
 * The active PermissionProvider (design 6D). Default: allow-all with a
 * once-per-node log line, so servers notice unenforced permissions
 * without spam. server{} permissions{} installs a MapPermissionProvider
 * at engine register; hosts may install anything else.
 */
public final class Permissions {
    /** Allow everything, log each distinct node once. */
    public static final class AllowAllProvider implements PermissionProvider {
        private final Set<String> logged = ConcurrentHashMap.newKeySet();

        @Override
        public boolean hasPermission(CommandSender sender, String permission) {
            if (logged.add(permission)) {
                System.out.println("[permissions] '" + permission + "' checked for "
                        + describe(sender) + ": default provider allows everything "
                        + "(declare server { permissions { ... } } or install a "
                        + "PermissionProvider to enforce)");
            }
            return true;
        }
    }

    private static volatile PermissionProvider provider = new AllowAllProvider();

    private Permissions() {
    }

    public static PermissionProvider provider() {
        return provider;
    }

    public static void setProvider(PermissionProvider replacement) {
        provider = replacement != null ? replacement : new AllowAllProvider();
    }

    public static boolean check(CommandSender sender, String permission) {
        return provider.hasPermission(sender, permission);
    }

    static String describe(CommandSender sender) {
        return sender instanceof Player player ? player.getUsername() : String.valueOf(sender);
    }
}
