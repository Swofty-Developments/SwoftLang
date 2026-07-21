storage {
    backend: files "data/game"
    flush: every 10 seconds
}

persistent leaderboard: map<Integer> = new_map()

command "score" {
    arguments { amount: Integer }
    execute {
        leaderboard.set(sender.name, (leaderboard.get(sender.name) otherwise 0) + args.amount)
        send "total ${leaderboard.get(sender.name) otherwise 0}" to sender
    }
}
