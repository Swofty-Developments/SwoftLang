command "ops" {
    execute {
        set x to 1 + 2 * 3                       // 7 — precedence
        set y to (1 + 2) * 3                     // 9 — parens group
        set ok to x > 6 and not (y < 5)
        if "SwoftLang" contains "swoft" {        // case-insensitive substring
            send "yes" to sender
        }
        if x is a Number and ok is not a String {
            send "typed" to sender
        }
    }
}
