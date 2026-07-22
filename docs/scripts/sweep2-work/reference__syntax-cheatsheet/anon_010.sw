command "find" {
    arguments {
        who: Optional<Player>                 // optional command argument
    }
    execute {
        set found to player("Notch")          // player() : Optional<Player>

        if found exists {
            send "hi ${found.name}" to found  // narrowed to Player here
        } else {
            send "offline" to sender
        }
        if found is missing {
            send "still missing" to sender
        }

        set target to args.who otherwise sender   // Optional<T> otherwise T -> T
        set label to none                         // the missing value
        set title to label otherwise "guest"
        send "${title}" to target
    }
}
