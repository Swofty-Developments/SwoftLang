// A super call may only invoke the base method being overridden; on_click may
// not super-call on_target.
mob "ghoul" {
    type: "ZOMBIE"
    on_click(player) {
        super.on_target(player)
    }
}
