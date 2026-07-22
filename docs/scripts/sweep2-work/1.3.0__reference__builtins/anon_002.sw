command "rounding" {
    execute {
        send "round(2.5) = ${round(2.5)}"      // 3
        send "floor(2.9) = ${floor(2.9)}"      // 2
        send "ceil(2.1)  = ${ceil(2.1)}"       // 3
    }
}
