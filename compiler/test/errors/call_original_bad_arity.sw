// 'call original method with arguments' arity must match the overridden base
// method: Mob.on_target takes one argument (target), not two.
mob "ghoul" {
    type: "ZOMBIE"
    on_target {
        call original method with arguments target, target
    }
}
