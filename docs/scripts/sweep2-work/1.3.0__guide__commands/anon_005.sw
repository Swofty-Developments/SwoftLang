command "give" {
    permission: "myserver.give"
    description: "Give an item to a player"

    arguments {
        material: String
        amount: Integer = 1
        target: Player = sender
    }

    execute {
        set stack to item(args.material, args.amount)
        send "gave ${args.target.name} ${args.amount}x ${args.material}" to sender
    }
}
