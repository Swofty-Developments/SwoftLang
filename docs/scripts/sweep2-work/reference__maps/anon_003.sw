command "intkeys" {
    execute {
        set names to { 1: "one", 2: "two", 3: "three" }

        set names at 4 to "four"             // Integer key
        set first to names[1] otherwise "none"
        send "first ${first}" to sender

        loop names as num -> word {          // key is an Integer, value a String
            send "${num} = ${word}" to sender
        }
    }
}
