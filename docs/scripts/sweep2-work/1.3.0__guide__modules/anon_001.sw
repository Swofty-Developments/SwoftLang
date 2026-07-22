import "./coins.sw"
import "music"

command "resolve-demo" {
    execute {
        send "both forms resolved at compile time" to sender
    }
}
