package net.swofty.compiler;

import java.util.List;

import net.swofty.nativebridge.representation.DataType;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * A user-declared function. Functions loaded from a module bundle carry
 * their owning module's name ({@code module}) and their export flag;
 * flat-script functions have a null module and are always globally visible.
 */
public record SwoftFunction(String name, List<Param> params, ExecuteBlock body, boolean async,
        String module, boolean exported) {

    public SwoftFunction(String name, List<Param> params, ExecuteBlock body, boolean async) {
        this(name, params, body, async, null, true);
    }

    public record Param(String name, DataType type) {
    }
}
