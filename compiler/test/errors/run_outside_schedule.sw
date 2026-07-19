// 'run' is only in scope inside an every/schedule/repeat body
command "bad" {
    execute {
        send "run is ${run}" to sender
    }
}
