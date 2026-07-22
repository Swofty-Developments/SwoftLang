persistent balance for Player: Integer = 100
persistent visits for OfflinePlayer: Integer = 0

command "reward" {
    arguments {
        who: String
        amount: Integer
    }
    execute {
        set target to offline_player(args.who)
        if target exists {
            // 'balance' is declared 'for Player' but takes the OfflinePlayer subject
            set balance for target to balance for target + args.amount
            send "paid ${args.amount} to ${target.name}" to sender
            if target.player exists {
                send "<green>+${args.amount} coins!" to target.player
            }
        }
    }
}
