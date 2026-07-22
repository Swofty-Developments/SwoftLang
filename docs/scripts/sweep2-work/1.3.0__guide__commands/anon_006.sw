command "give" {
    arguments {
        material: String
        amount: Integer = 1
        target: Player = sender
    }
    execute {
        send "<green>Gave ${args.target.name} ${args.amount}x ${args.material}" to sender
    }
}
