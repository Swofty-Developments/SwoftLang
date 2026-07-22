command "visit" {
    arguments {
        dest: either<Player|Location>
    }
    execute {
        send "heading to x=${args.dest.x}" to sender
    }
}
