command "grade" {
    arguments {
        score: Integer
    }
    execute {
        if args.score >= 90 {
            send "gold tier" to sender
        } else if args.score >= 50 {
            send "silver tier" to sender
        } else {
            send "bronze tier" to sender
        }
    }
}
