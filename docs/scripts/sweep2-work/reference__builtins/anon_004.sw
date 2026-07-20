command "mathgaps" {
    execute {
        set hyp to sqrt(pow(3, 2) + pow(4, 2))   // 5.0
        set rem to mod(10, 3)                      // 1
        set pi_ish to round_to(3.14159, 2)         // 3.14
        set dir to sign(0 - 42)                    // -1
        send "${hyp} ${rem} ${pi_ish} ${dir}" to sender
    }
}
