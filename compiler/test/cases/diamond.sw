import "./mod/dia_b.sw"
import "./mod/dia_c.sw"

command "diamond" {
    execute {
        send "sum = ${twice() + thrice()}" to sender
    }
}
