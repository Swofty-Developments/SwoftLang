// bank.sw — an entry script using the module
import "./coins.sw"

command "payday" {
    execute {
        if sender is a Player {
            give_coins(sender, 250)
            send "<gray>minted so far: ${coins_minted()}" to sender
        }
    }
}
