function ping(target) {
    send "ping" to target
    return
}

function sum(a: Integer, b: Integer) {
    return a + b
}

function countdown(n: int) {
    if n > 0 {
        broadcast "${n}"
        countdown(n - 1)
    }
}

function nothing() {
    halt
}

command "use" {
    execute {
        ping(sender)
        call countdown(3)
        set total to sum(1, 2)
        nothing()
    }
}
