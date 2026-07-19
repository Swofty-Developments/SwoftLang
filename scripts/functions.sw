function factorial(n: int) {
    if n <= 1 {
        return 1
    }
    return n * factorial(n - 1)
}

function greet(player: Player) {
    send "Welcome, ${player}!" to player
}

function add(a: int, b: int) {
    return a + b
}

command "functions" {
    description: "Showcase of SwoftLang functions"

    execute {
        set f to factorial(5)
        send "factorial(5) = ${f}"
        send "factorial(0) = " + factorial(0)
        set s to add(add(1, 2), add(3, 4))
        send "nested add = ${s}"
        call greet(sender)
        greet(sender)
        if factorial(4) = 24 {
            send "factorial(4) = 24"
        }
        send "uppercase = " + uppercase("swoft")
        send "before return"
        return
        send "after return"
    }
}
