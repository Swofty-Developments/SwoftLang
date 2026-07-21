command "intkeys" {
    execute {
        set names to { 1: "one", 2: "two", 3: "three" }

        names.set(4, "four")                 // Integer key
        set first to names.get(1) otherwise "none"
        send "first ${first}" to sender

        loop names as num -> word {          // key is an Integer, value a String
            send "${num} = ${word}" to sender
        }
    }
}
