command "status" {
    execute {
        set h to schedule every 1 seconds as "ticker" {
            if run >= 10 stop
        }
        if is_running(h) send "ticker up" to sender
        cancel schedule "ticker"
    }
}
