command "dump" {
    execute {
        set counts to { "a": 1, "b": 2 }

        loop keys of counts as key {
            send "key ${key}" to sender
        }

        loop counts as name -> amount {
            send "${name} = ${amount}" to sender
        }
    }
}
