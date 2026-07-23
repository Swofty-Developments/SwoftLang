async function slow() {
    wait 1 ticks
    return 5
}

mob Ghoul {
    type: "ZOMBIE"
    ai {
        target closest Player within 10
        goal "chase" {
            on_tick {
                set n to await spawn slow()
                path mob to target at speed n
            }
        }
    }
}
