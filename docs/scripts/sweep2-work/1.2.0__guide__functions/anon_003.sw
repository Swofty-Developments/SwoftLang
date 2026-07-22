function fib(n: Integer) {
    if n <= 1 {
        return n
    }
    return fib(n - 1) + fib(n - 2)
}

command "fib" {
    execute {
        send "fib(10) = ${fib(10)}"
    }
}
