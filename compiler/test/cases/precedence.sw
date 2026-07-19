command "prec" {
    execute {
        set p to true
        set q to false
        set x to 4
        set done to false
        set items to "abc"
        set prefix to "a"
        set suffix to "b"
        set a to 1 + 2 * 3
        set b to not p and q
        set c to 1 + 2 < 3 * 4 or x % 2 == 0 and not done
        set d to -2 * 3 + 1
        set e to items contains prefix + suffix
        set f to a is not b + 1
        set g to not x contains "y"
    }
}
