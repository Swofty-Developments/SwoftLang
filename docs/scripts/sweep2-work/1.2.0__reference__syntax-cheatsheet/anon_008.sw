function factorial(n: int) {
    if n <= 1 {
        return 1
    }
    return n * factorial(n - 1)               // recursion (depth cap 256)
}

function greet(player: Player) {
    send "Welcome, ${player}!" to player
}

command "demo" {
    execute {
        set f to factorial(5)                 // call as expression
        greet(sender)                         // call as statement
        call greet(sender)                    // optional 'call' keyword
        return                                // bare return = stop, like halt
    }
}
