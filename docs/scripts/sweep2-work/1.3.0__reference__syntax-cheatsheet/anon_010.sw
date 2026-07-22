command "find" {
    arguments {
        who: optional<Player>                 // optional command argument
    }
    execute {
        set found to player("Notch")          // player() : optional<Player>

        if found exists {
            send "hi ${found.name}" to found  // narrowed to Player here
        } else {
            send "offline" to sender
        }
        if found is missing {
            send "still missing" to sender
        }

        set target to args.who otherwise sender   // optional<T> otherwise T -> T
        set label to none                         // the missing value
        set title to label otherwise "guest"
        send "${title}" to target
    }
}
