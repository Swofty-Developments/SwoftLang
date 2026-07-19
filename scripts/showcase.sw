command "demo" {
    description: "Showcase of SwoftLang language features"

    execute {
        // variables and arithmetic precedence
        set x to 1 + 2 * 3
        send "x = ${x}"
        set y to (1 + 2) * 3
        send "y = ${y}"
        set z to 10 - 4 / 2
        send "z = ${z}"
        set r to 17 % 5
        send "17 mod 5 = ${r}"
        set neg to -5
        send "neg = ${neg}"
        set half to 7 / 2.0
        send "half = ${half}"

        // comparisons and booleans
        if x > 6 {
            send "x is greater than 6"
        }
        if x = 7 {
            send "x equals 7"
        }
        if x != 8 {
            send "x is not 8"
        }
        set flag to true
        if flag and x >= 7 {
            send "flag and x >= 7"
        }
        if not (x < 5) {
            send "x is not less than 5"
        }

        /* if / else if / else */
        if x = 5 {
            send "branch: five"
        } else if x = 7 {
            send "branch: seven"
        } else {
            send "branch: other"
        }

        // loop N times as i
        loop 3 times as i {
            send "loop iteration ${i}"
        }

        // while
        set countdown to 3
        while countdown > 0 {
            send "countdown ${countdown}"
            set countdown to countdown - 1
        }

        // interpolation and + concat
        set name to "SwoftLang"
        send "Hello from ${name}, x + y = " + (x + y)

        // contains (case-insensitive)
        if name contains "swoft" {
            send "name contains swoft"
        }
        if name contains "java" {
            send "name contains java"
        } else {
            send "name does not contain java"
        }

        // is a checks
        if x is a Number {
            send "x is a Number"
        }
        if name is a String {
            send "name is a String"
        }
        if flag is not a Number {
            send "flag is not a Number"
        }

        send "flag = ${flag}"

        // broadcast needs a running server; keep it off the harness path
        if false {
            broadcast "<gold>Hello everyone"
        }

        send "demo complete"
    }
}
