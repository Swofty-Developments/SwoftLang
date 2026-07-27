package net.swofty.persist.network;

import net.minestom.server.entity.Player;
import net.swofty.TextFormat;
import net.swofty.model.CoordinatorModel;
import net.swofty.model.HandoffFailureModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.persist.PersistStore;
import net.swofty.persist.SwoftStorage;

/**
 * Everything {@code mode: network} adds to the {@link PersistStore} (design
 * 1.10.0 §6), assembled in one place so that {@code mode: standalone} allocates
 * none of it and takes none of its branches.
 *
 * <p>Owns the lease manager (session ownership), the change bus, the global
 * replica, and the shared version-stamp table. Chooses the coordinator-backed
 * implementations when {@code coordinator: redis} is configured and the
 * backend-table fallbacks otherwise.
 */
public final class NetworkRuntime {

    private final StorageConfigModel config;
    private final String serverId;
    private final LeaseManager leases;
    private final BroadcastChannel channel;
    private final GlobalReplica replica;
    private final VersionStamps versions;

    private NetworkRuntime(StorageConfigModel config, String serverId, LeaseManager leases,
            BroadcastChannel channel, GlobalReplica replica, VersionStamps versions) {
        this.config = config;
        this.serverId = serverId;
        this.leases = leases;
        this.channel = channel;
        this.replica = replica;
        this.versions = versions;
    }

    /**
     * Build and start the network runtime for an already-loaded store: globals
     * are in the replica by now (loaded eagerly at boot, §2.3), so subscribing
     * here cannot miss a change it also has to apply.
     */
    public static NetworkRuntime start(PersistStore store, StorageConfigModel config,
            SwoftStorage storage) {
        return start(store, config, storage, ServerIdentity.id());
    }

    /**
     * As {@link #start(PersistStore, StorageConfigModel, SwoftStorage)} but with
     * an explicit server identity. {@link ServerIdentity} resolves once per JVM,
     * which is right for a real deployment (one server per process) and wrong
     * for the two-server harness, where two runtimes share a process and must
     * NOT share a lease owner token or an {@code origin_server} — with one id
     * between them every lease would look self-held and every broadcast would be
     * dropped as its own echo.
     */
    public static NetworkRuntime start(PersistStore store, StorageConfigModel config,
            SwoftStorage storage, String serverId) {
        warnAboutUnshareableBackend(config);

        VersionStamps versions = new VersionStamps();
        LeaseStore leaseStore = null;
        BroadcastChannel channel = null;

        CoordinatorModel coordinator = config.coordinator();
        if (coordinator != null && "redis".equalsIgnoreCase(coordinator.kind())) {
            try {
                leaseStore = new RedisLeaseStore(RedisConnection.open(coordinator.uri(), 3_000));
                channel = new RedisBroadcastChannel(coordinator.uri(), serverId,
                        RedisConnection.open(coordinator.uri(), 3_000));
                System.out.println("[persist] coordinator: redis " + coordinator.uri());
            } catch (Exception e) {
                System.err.println("[persist] cannot reach the redis coordinator at "
                        + coordinator.uri() + " (" + e.getMessage()
                        + ") - falling back to the backend lease table and polled bus");
                leaseStore = null;
                channel = null;
            }
        }
        if (leaseStore == null) {
            leaseStore = new BackendLeaseStore(storage);
        }
        if (channel == null) {
            channel = new BackendBusChannel(storage, serverId);
        }

        LeaseManager leases = new LeaseManager(leaseStore, serverId);
        // a lease this server is proven to have LOST must take the cached rows
        // with it, or the crash checkpoint keeps a stale copy alive in memory
        leases.onLeaseLost(store::evictSession);
        GlobalReplica replica = new GlobalReplica(store, storage, channel, versions, serverId);
        replica.start();

        NetworkRuntime runtime = new NetworkRuntime(config, serverId, leases, channel,
                replica, versions);
        SessionOwnership.install(store, runtime);
        System.out.println("[persist] mode: network, server id '" + serverId
                + "' - per-player values are session-owned, globals are replicated");
        return runtime;
    }

    public LeaseManager leases() {
        return leases;
    }

    public GlobalReplica replica() {
        return replica;
    }

    public VersionStamps versions() {
        return versions;
    }

    public String serverId() {
        return serverId;
    }

    /**
     * §2.1.5: the handoff failed, so this player must not be let in with unowned
     * data. The default policy is a kick with the configured message; nothing
     * here ever falls back to serving defaults.
     */
    public void applyHandoffFailure(Player player, String reason) {
        HandoffFailureModel policy = config.handoffFailureOrDefault();
        System.err.println("[persist] handoff failed for " + player.getUsername()
                + " (" + reason + ") - applying on_handoff_failure: " + policy.action());
        if (!"kick".equalsIgnoreCase(policy.action())) {
            System.err.println("[persist] unknown on_handoff_failure action '"
                    + policy.action() + "' - kicking, because serving default or"
                    + " duplicated data is never an option");
        }
        try {
            player.kick(TextFormat.component(policy.messageOrDefault()));
        } catch (Throwable t) {
            System.err.println("[persist] kicking " + player.getUsername() + " failed: " + t);
        }
    }

    /**
     * Hot-reload integration (§6). A reload rebuilds the program, not the
     * persistence layer: leases of still-connected players are RENEWED (never
     * released — the player never left, and dropping the lease would let another
     * server load their data underneath them), and the replica subscription is
     * left running, since nothing re-subscribes it afterwards. Only a full
     * shutdown or a store replacement tears the subscription down, and that path
     * goes through {@link #close()}.
     */
    public void onReload() {
        leases.renewAll();
    }

    /** Clean teardown: detach the hooks, release every lease, close the bus. */
    public void close() {
        SessionOwnership.uninstall();
        try {
            channel.close();
        } catch (Exception e) {
            System.err.println("[persist] closing the change bus failed: " + e.getMessage());
        }
        try {
            leases.close();
        } catch (Exception e) {
            System.err.println("[persist] releasing leases failed: " + e.getMessage());
        }
    }

    /**
     * §1 validation is the compiler's job (a files/sqlite backend under
     * {@code mode: network} is a compile error), but a hand-built config or a
     * stale sidecar can still reach the runtime — say so loudly rather than
     * pretend the servers are coordinating.
     */
    private static void warnAboutUnshareableBackend(StorageConfigModel config) {
        String kind = config.backend() != null ? config.backend().kind() : null;
        if ("files".equals(kind) || "sqlite".equals(kind)) {
            System.err.println("[persist] mode: network with a '" + kind + "' backend:"
                    + " that backend cannot coordinate servers, so leases and"
                    + " replication only work if every server shares this exact"
                    + " storage - use mysql or mongodb");
        }
    }
}
