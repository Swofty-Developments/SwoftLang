command "smite" {
    arguments {
        victim: Either<Player|Location>
    }
    execute {
        if args.victim is not a Player {
            send "<red>You can only smite players" to sender
            halt
        }
        send "<gold>Smitten." to sender
    }
}
