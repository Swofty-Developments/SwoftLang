package net.swofty.mobs;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.TextDecoration;
import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityCreature;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.ItemEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.ai.GoalSelector;
import net.minestom.server.entity.ai.TargetSelector;
import net.minestom.server.entity.ai.goal.MeleeAttackGoal;
import net.minestom.server.entity.ai.goal.RandomStrollGoal;
import net.minestom.server.entity.ai.target.ClosestEntityTarget;
import net.minestom.server.entity.ai.target.LastEntityDamagerTarget;
import net.minestom.server.entity.attribute.Attribute;
import net.minestom.server.entity.damage.Damage;
import net.minestom.server.entity.damage.EntityDamage;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.utils.time.TimeUnit;
import net.swofty.ASTExecutor;
import net.swofty.TextFormat;
import net.swofty.handlers.HandlerDispatch;
import net.swofty.handlers.InlineHandlerRuntime;
import net.swofty.items.ItemLoreBuilder;
import net.swofty.items.ItemRegistry;
import net.swofty.mobs.event.MobDamageEvent;
import net.swofty.mobs.event.MobDeathEvent;
import net.swofty.mobs.event.MobSpawnEvent;
import net.swofty.model.MobDefModel;
import net.swofty.model.MobDropModel;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.NoneValue;
import net.swofty.runtime.SystemSender;
import net.swofty.runtime.Values;

/**
 * The scripted mob runtime (design 5B): an EntityCreature subclass driven
 * by a MobDefModel. All definition-dependent init runs AFTER super()
 * returns (no ThreadLocal handoff needed, unlike the SkyBlock repo).
 * Attribute setup per the pinned API; AI groups from the pinned goal/target
 * classes (javap-verified: MeleeAttackGoal(EntityCreature,double,int,
 * TemporalUnit), RandomStrollGoal(EntityCreature,int),
 * ClosestEntityTarget(EntityCreature,double,Predicate&lt;Entity&gt;),
 * LastEntityDamagerTarget(EntityCreature,float)). The custom name is
 * re-rendered live on every damage/heal.
 */
public class SwoftMob extends EntityCreature {
    private static final long ATTACK_COOLDOWN_MILLIS = 500;

    private final MobDefModel def;
    /**
     * Live, in-memory store for the mob's declared typed tags (design
     * W-viewers feature 2). A {@code map<Player,Integer>} tag is a real
     * {@link net.swofty.runtime.MapValue} here — indexable and mutable with no
     * NBT serialization — sitting alongside (and shadowing, by key) the freeform
     * NBT {@code entity.tags} store. Seeded once at construction.
     */
    private final Map<String, Object> liveTags = new java.util.concurrent.ConcurrentHashMap<>();
    private volatile String nameOverride;
    private volatile double attackDamage;
    private volatile long lastAttackMillis;
    private volatile boolean deathHandled;

    public SwoftMob(MobDefModel def) {
        super(resolveType(def.type()));
        this.def = def;
        this.attackDamage = def.damage();

        getAttribute(Attribute.MAX_HEALTH).setBaseValue(def.health());
        setHealth((float) def.health());
        getAttribute(Attribute.MOVEMENT_SPEED).setBaseValue(def.speed());
        getAttribute(Attribute.ATTACK_DAMAGE).setBaseValue(def.damage());

        // viewable:false => hidden until an explicit `show <mob> to ...`. Set
        // before spawn so setInstance never auto-adds viewers.
        setAutoViewable(def.viewable());
        seedTypedTags();

        setCustomNameVisible(true);
        renderName();
        applyAi();
    }

    /** Seed the declared typed tags with live empty containers / init values. */
    private void seedTypedTags() {
        for (net.swofty.model.MobTagDecl tag : def.tags().values()) {
            switch (tag.kind()) {
                case MAP -> liveTags.put(tag.name(), new net.swofty.runtime.MapValue());
                case LIST -> liveTags.put(tag.name(), new java.util.ArrayList<>());
                case SCALAR -> liveTags.put(tag.name(),
                        tag.initValue() == null ? NoneValue.INSTANCE : tag.initValue());
            }
        }
    }

    /** True when {@code key} is a declared typed/value tag (live store). */
    public boolean hasLiveTag(String key) {
        return liveTags.containsKey(key);
    }

    /** The live value of a declared tag, or null when undeclared. */
    public Object liveTag(String key) {
        return liveTags.get(key);
    }

    /** The mutable live typed-tag store (used by {@code mob.tags} writes). */
    public Map<String, Object> liveTags() {
        return liveTags;
    }

    public static EntityType resolveType(String type) {
        String key = type.contains(":") ? type.toLowerCase() : "minecraft:" + type.toLowerCase();
        EntityType entityType = EntityType.fromKey(key);
        if (entityType == null) {
            throw new net.swofty.ScriptError("unknown entity type '" + type + "'");
        }
        return entityType;
    }

    private void applyAi() {
        switch (def.ai()) {
            case "melee" -> addAIGroup(
                    List.<GoalSelector>of(
                            new MeleeAttackGoal(this, 1.6, 20, TimeUnit.SERVER_TICK),
                            new RandomStrollGoal(this, 15)),
                    List.<TargetSelector>of(
                            new LastEntityDamagerTarget(this, 16f),
                            new ClosestEntityTarget(this, 16d,
                                    entity -> entity instanceof Player player
                                            && !player.isDead())));
            case "passive" -> addAIGroup(
                    List.<GoalSelector>of(new RandomStrollGoal(this, 15)),
                    List.<TargetSelector>of());
            default -> {
                // "none": no AI
            }
        }
    }

    public MobDefModel getDef() {
        return def;
    }

    public String getCustomIdString() {
        return def.id();
    }

    public double getAttackDamage() {
        return attackDamage;
    }

    public void setAttackDamage(double attackDamage) {
        this.attackDamage = attackDamage;
        getAttribute(Attribute.ATTACK_DAMAGE).setBaseValue(attackDamage);
    }

    /** Replace the live name template with a static string and re-render. */
    public void setNameOverride(String name) {
        this.nameOverride = name;
        renderName();
    }

    /**
     * Re-evaluate the name template (mob bound, so ${mob.health} style
     * interpolation is live) into the entity custom name.
     */
    public final void renderName() {
        String raw;
        if (nameOverride != null) {
            raw = nameOverride;
        } else if (def.name() != null) {
            Map<String, Object> vars = new HashMap<>();
            vars.put("mob", this);
            raw = new ASTExecutor(handlerSender(), vars).evaluateStringExpression(def.name());
        } else {
            raw = def.id();
        }
        Component component = ItemLoreBuilder.isMiniMessage(raw)
                ? TextFormat.component(raw).decoration(TextDecoration.ITALIC, false)
                : Component.text(raw.replace("&", "§")).decoration(TextDecoration.ITALIC, false);
        setCustomName(component);
    }

    @Override
    public void spawn() {
        super.spawn();
        MobRegistry.track(this);
        runHandler(def.onSpawn(), baseVars());
        EventDispatcher.call(new MobSpawnEvent(this));
    }

    @Override
    public boolean damage(Damage damage) {
        // per-mob on_damage first (damage/cancelled read back from the env)
        if (def.onDamage() != null && !def.onDamage().isEmpty()) {
            Map<String, Object> vars = baseVars();
            vars.put("attacker", damage.getAttacker() != null
                    ? damage.getAttacker() : NoneValue.INSTANCE);
            vars.put("damage", (double) damage.getAmount());
            vars.put("cancelled", false);
            runHandler(def.onDamage(), vars);
            if (Values.toBoolean(vars.get("cancelled"))) {
                return false;
            }
            Object amount = vars.get("damage");
            if (amount instanceof Number number) {
                damage.setAmount(number.floatValue());
            }
        }

        // then the global MobDamage wrapper event
        MobDamageEvent event = new MobDamageEvent(this, damage.getAttacker(),
                damage.getAmount());
        EventDispatcher.call(event);
        if (event.isCancelled()) {
            return false;
        }
        damage.setAmount((float) event.getAmount());

        boolean result = super.damage(damage);
        renderName();
        return result;
    }

    @Override
    public void kill() {
        if (!deathHandled) {
            deathHandled = true;
            MobRegistry.untrack(this);

            Player killer = null;
            Damage lastDamage = getLastDamageSource();
            if (lastDamage != null && lastDamage.getAttacker() instanceof Player player) {
                killer = player;
            }

            Map<String, Object> vars = baseVars();
            vars.put("killer", killer != null ? killer : NoneValue.INSTANCE);
            runHandler(def.onDeath(), vars);
            EventDispatcher.call(new MobDeathEvent(this, killer));
            rollDrops();
        }
        super.kill();
    }

    @Override
    public void remove() {
        MobRegistry.untrack(this);
        net.swofty.entities.EntityNametagRuntime.forget(this);
        super.remove();
    }

    /** Drops on death: custom item registry ids or vanilla material fallback. */
    private void rollDrops() {
        if (getInstance() == null) {
            return;
        }
        for (MobDropModel drop : def.drops()) {
            if (ThreadLocalRandom.current().nextDouble() >= drop.chance()) {
                continue;
            }
            ItemStack stack;
            if (ItemRegistry.get(drop.itemId()) != null) {
                stack = ItemRegistry.build(drop.itemId(), drop.amount());
            } else {
                Material material = Material.fromKey(drop.itemId().contains(":")
                        ? drop.itemId().toLowerCase()
                        : "minecraft:" + drop.itemId().toLowerCase());
                if (material == null) {
                    System.err.println("Warning: mob '" + def.id() + "' drop '"
                            + drop.itemId() + "' is neither a custom item nor a material");
                    continue;
                }
                stack = ItemStack.of(material, drop.amount());
            }
            ItemEntity itemEntity = new ItemEntity(stack);
            itemEntity.setInstance(getInstance(), getPosition().add(0, 0.5, 0));
        }
    }

    /**
     * Mob-to-player melee application, called from the EntityAttackEvent
     * listener; gated by a 500 ms per-mob cooldown like the SkyBlock
     * damageCooldown mechanism.
     */
    public void tryAttack(Player target) {
        long now = System.currentTimeMillis();
        if (now - lastAttackMillis < ATTACK_COOLDOWN_MILLIS) {
            return;
        }
        lastAttackMillis = now;

        double amount = attackDamage;
        if (def.onAttack() != null && !def.onAttack().isEmpty()) {
            Map<String, Object> vars = baseVars();
            vars.put("victim", target);
            vars.put("damage", amount);
            vars.put("cancelled", false);
            runHandler(def.onAttack(), vars);
            if (Values.toBoolean(vars.get("cancelled"))) {
                return;
            }
            Object override = vars.get("damage");
            if (override instanceof Number number) {
                amount = number.doubleValue();
            }
        }
        if (amount > 0) {
            target.damage(new EntityDamage(this, (float) amount));
        }
    }

    /**
     * Player-melee-hits-mob application, called from the EntityAttackEvent
     * listener when a player swings at this mob. The mob decl's on_hit body
     * runs first with mob + attacker bound; if it sets cancelled the hit is
     * dropped entirely (no damage, no on_damage). Otherwise the flat base
     * melee hit applies, which then flows through damage() -> on_damage +
     * the MobDamage wrapper event as usual.
     */
    public void handleMeleeHit(Player attacker) {
        if (def.onHit() != null && !def.onHit().isEmpty()) {
            Map<String, Object> vars = baseVars();
            vars.put("attacker", attacker);
            vars.put("cancelled", false);
            runHandler(def.onHit(), vars);
            if (Values.toBoolean(vars.get("cancelled"))) {
                return;
            }
        }
        damage(Damage.fromPlayer(attacker, (float) MobRuntime.playerMeleeDamage(attacker)));
    }

    private Map<String, Object> baseVars() {
        Map<String, Object> vars = new HashMap<>();
        vars.put("mob", this);
        return vars;
    }

    /**
     * The mob on_hit dispatch core, now shared with every inline handler
     * through {@link HandlerDispatch#run}: run a sync handler body with the
     * bound vars, isolating script errors from the firing event.
     */
    private void runHandler(ExecuteBlock block, Map<String, Object> vars) {
        HandlerDispatch.run(handlerSender(), block, vars, "mob '" + def.id() + "'");
    }

    /**
     * AI target acquire/lose/change -> the generic {@code on_target} handler
     * (bound {@code this} = mob, {@code target} = optional<Entity>). Forwarded
     * to the single filtered dispatcher, which no-ops when undeclared.
     */
    @Override
    public void setTarget(Entity target) {
        Entity previous = getTarget();
        super.setTarget(target);
        if (previous != target) {
            InlineHandlerRuntime.dispatchMob(this, "on_target", target);
        }
    }

    /**
     * Per-tick -> the generic {@code on_tick} handler. The dispatcher's map
     * lookup short-circuits when no on_tick is declared, so mobs without one
     * pay only that lookup ("presence => ticking").
     */
    @Override
    public void tick(long time) {
        super.tick(time);
        InlineHandlerRuntime.dispatchMob(this, "on_tick");
    }

    private static CommandSender handlerSender() {
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }

    @Override
    public String toString() {
        // called from the Entity super constructor before def is assigned
        return "mob:" + (def != null ? def.id() : "<initializing>");
    }
}
