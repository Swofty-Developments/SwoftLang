package net.swofty.model;

import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * api "/path/:param" { method: ..., execute async { ... } } declaration
 * (design 6B). Path segments starting with ':' capture into
 * request.params.&lt;name&gt;; method is get|post|put|delete|any.
 */
public record ApiHandlerModel(
        String path,
        String method,
        ExecuteBlock execute,
        int line,
        int col) {
}
