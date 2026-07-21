// default() re-runs an overridden base method; it is illegal inside a base
// receiver method, which overrides nothing.
Mob {
    on_click(player) {
        default()
    }
}
