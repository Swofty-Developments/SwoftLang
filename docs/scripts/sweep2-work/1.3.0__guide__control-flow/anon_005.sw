command "launch" {
    arguments {
        countdown: Integer
    }
    execute {
        if args.countdown > 60 {
            send "<red>too long - 60s max" to sender
            halt
        }
        send "launching in ${args.countdown}s" to sender
    }
}
