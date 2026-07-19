import "./mod/exportmix.sw"

command "blade" {
    execute {
        give_blade(sender)
        give item "mix_blade" to sender
    }
}
