function double(x: Integer) return x * 2      // brace-free body

command "lambda" {
    execute {
        set triple to function(x: Integer) return x * 3
        send "${triple(4)}" to sender         // 12: call through the variable

        set count to 0
        set inc to function() set count to count + 1
        inc()                                 // closures capture by reference
        send "${count}" to sender             // 1

        set task to async function(p: Player) {
            wait 1 seconds
            send "later" to p
        }
        spawn task(sender)                    // spawn works on async lambdas
    }
}
