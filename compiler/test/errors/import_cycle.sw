import "./mod/cyc_one.sw"

command "cycle" {
    execute {
        send "${one()}" to sender
    }
}
