persistent balance for Player: Integer = 100

command "reward" {
    arguments {
        who: String
        amount: Integer
    }
    execute {
        set target to offline_player(args.who)
        if target exists {
            set balance for target to balance for target + args.amount
            send "<gray>Paid ${args.amount} to ${target.name}" to sender
            if target.player exists {
                send "<green>+${args.amount} coins!" to target.player
            }
        }
    }
}
