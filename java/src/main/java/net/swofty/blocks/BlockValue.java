package net.swofty.blocks;

import java.io.IOException;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

import net.kyori.adventure.nbt.CompoundBinaryTag;
import net.kyori.adventure.nbt.TagStringIO;
import net.minestom.server.instance.block.Block;
import net.minestom.server.tag.Tag;
import net.swofty.ScriptError;
import net.swofty.props.NoneValue;
import net.swofty.runtime.MapValue;

/**
 * Immutable SwoftLang wrapper over a Minestom {@link Block} (W-blocks). A
 * Minestom {@code Block} is an interned flyweight of {@code (stateId, nbt,
 * handler)}; every {@code withX} returns a <em>new</em> block rather than
 * mutating, so this wrapper is a thin value with the same value semantics.
 *
 * <p>Created by the {@code block("id")} / {@code block("id", {props})} builtins
 * and by {@code block_at(location)}, threaded through the runtime as the
 * {@code Block} script type, and unwrapped again by {@code set block} /
 * {@code fill blocks} / {@code set_block} placement.
 *
 * <p>The key robustness contract (design §1, gotcha #4): Minestom's
 * {@code Block.withProperty} <em>silently</em> returns the block unchanged when
 * the property name or value is invalid. {@link #with(String, String)} instead
 * validates against the block's own {@code possibleStates()} schema and throws
 * a {@link ScriptError} with the allowed values — no silent failure.
 */
public final class BlockValue {
    private final Block block;

    public BlockValue(Block block) {
        this.block = block;
    }

    /** The wrapped Minestom block (for placement into an instance). */
    public Block block() {
        return block;
    }

    /** The namespaced id, e.g. {@code "minecraft:oak_stairs"}. */
    public String id() {
        return block.key().asString();
    }

    // -------------------------- properties ----------------------------

    /**
     * A pure {@code withProperty} that validates first: unknown property or
     * out-of-schema value throws instead of silently returning the block
     * unchanged. The schema is derived from this block family's
     * {@code possibleStates()} (there is no single key→values API).
     */
    public BlockValue with(String property, String value) {
        Set<String> keys = block.properties().keySet();
        if (!keys.contains(property)) {
            throw new ScriptError("block " + id() + " has no property '" + property
                    + "'; valid properties: " + String.join(", ", new TreeSet<>(keys)));
        }
        Set<String> allowed = allowedValues(property);
        if (!allowed.contains(value)) {
            throw new ScriptError("'" + value + "' is not a valid value for property '"
                    + property + "' of block " + id() + "; valid values: "
                    + String.join(", ", allowed));
        }
        return new BlockValue(block.withProperty(property, value));
    }

    /** Apply several validated property changes at once (pure). */
    public BlockValue withProperties(Map<String, String> properties) {
        BlockValue current = this;
        for (Map.Entry<String, String> entry : properties.entrySet()) {
            current = current.with(entry.getKey(), entry.getValue());
        }
        return current;
    }

    /** The value of one property in this state, or {@code none} if absent. */
    public Object property(String property) {
        String value = block.getProperty(property);
        return value != null ? value : NoneValue.INSTANCE;
    }

    /** This state's full property map, as a script {@code map<String,String>}. */
    public MapValue properties() {
        MapValue map = new MapValue();
        for (Map.Entry<String, String> entry : block.properties().entrySet()) {
            map.put(entry.getKey(), entry.getValue());
        }
        return map;
    }

    /** The distinct allowed values for one property across all states. */
    private Set<String> allowedValues(String property) {
        Set<String> values = new LinkedHashSet<>();
        for (Block state : block.possibleStates()) {
            String value = state.getProperty(property);
            if (value != null) {
                values.add(value);
            }
        }
        return values;
    }

    // ----------------------------- NBT --------------------------------

    /**
     * The block-entity NBT as an SNBT string, or {@code none} when the block
     * carries no NBT (design types {@code block.nbt} as {@code optional<String>}).
     */
    public Object nbt() {
        CompoundBinaryTag nbt = block.nbt();
        if (nbt == null || nbt.size() == 0) {
            return NoneValue.INSTANCE;
        }
        return snbt(nbt);
    }

    /** Attach block-entity NBT parsed from an SNBT string (pure). */
    public BlockValue withNbt(String snbt) {
        return new BlockValue(block.withNbt(parseSnbt(snbt)));
    }

    /** Read a String-typed block tag, or {@code none} if unset. */
    public Object getTag(String name) {
        String value = block.getTag(Tag.String(name));
        return value != null ? value : NoneValue.INSTANCE;
    }

    /** Set a String-typed block tag (pure). */
    public BlockValue withTag(String name, String value) {
        return new BlockValue(block.withTag(Tag.String(name), value));
    }

    private static CompoundBinaryTag parseSnbt(String snbt) {
        String text = snbt == null ? "" : snbt.trim();
        if (text.isEmpty()) {
            return CompoundBinaryTag.empty();
        }
        try {
            return TagStringIO.tagStringIO().asCompound(text);
        } catch (IOException e) {
            throw new ScriptError("invalid block NBT '" + snbt + "': " + e.getMessage());
        }
    }

    private static String snbt(CompoundBinaryTag nbt) {
        try {
            return TagStringIO.tagStringIO().asString(nbt);
        } catch (IOException e) {
            return nbt.toString();
        }
    }

    /** All allowed values for a property, exposed for validation reuse. */
    public Collection<String> validValues(String property) {
        return allowedValues(property);
    }

    @Override
    public String toString() {
        // matches vanilla blockstate strings, e.g. oak_stairs[facing=north]
        Map<String, String> props = block.properties();
        if (props.isEmpty()) {
            return id();
        }
        StringBuilder sb = new StringBuilder(id()).append('[');
        boolean first = true;
        for (Map.Entry<String, String> entry : props.entrySet()) {
            if (!first) {
                sb.append(',');
            }
            first = false;
            sb.append(entry.getKey()).append('=').append(entry.getValue());
        }
        return sb.append(']').toString();
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof BlockValue value && block.equals(value.block);
    }

    @Override
    public int hashCode() {
        return block.hashCode();
    }
}
