command "totals" {
    execute {
        set scores to [10, 20, 30]
        send "sum ${sum(scores)} product ${product(scores)}" to sender
    }
}
