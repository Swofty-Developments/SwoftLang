function reward(target: Player, amount: Integer) {
    send "<gold>You earned ${amount} coins" to target
}

command "payday" {
    execute {
        if sender is a Player {
            reward(sender, 250)
        }
    }
}
