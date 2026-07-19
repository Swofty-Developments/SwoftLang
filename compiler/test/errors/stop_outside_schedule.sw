// 'stop' is only legal inside an every/schedule/repeat body
command "bad" {
    execute {
        stop
    }
}
