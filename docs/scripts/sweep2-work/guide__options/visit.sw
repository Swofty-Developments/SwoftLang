command "visit" {
    arguments {
        dest: Either<Player|Location>
    }
    execute {
        send "heading to x=${args.dest.x}" to sender
    }
}
