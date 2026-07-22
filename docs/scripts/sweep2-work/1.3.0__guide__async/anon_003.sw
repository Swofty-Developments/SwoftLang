async function fetch_bonus(base: Integer) {
    wait 100 millis
    return base * 2
}

command "bonus" {
    execute async {
        send "crunching..." to sender
        set b to fetch_bonus(50)
        send "your bonus is ${b}" to sender
    }
}
