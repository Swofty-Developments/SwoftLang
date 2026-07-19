import "./mod/shadowlib.sw"

function helper() {
    return "local"
}

command "shadow" {
    execute {
        send helper() to sender
    }
}
