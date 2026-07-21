// 'call original method' no longer accepts a 'with arguments' clause: forward a
// changed value by mutating the bound variable before the bare call. The old
// 'with arguments' syntax is now a parse error.
mob "ghoul" {
    type: "ZOMBIE"
    on_target {
        call original method with arguments target
    }
}
