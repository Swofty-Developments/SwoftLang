// §4.4: a reactive field may NOT be typed as a custom type (it owns its
// behavior in its own `mob Ghoul` block).
mob Ghoul {
    type: "ZOMBIE"
    health: 40
}

struct Arena {
    @EventReceiver anchor: Ghoul
}
