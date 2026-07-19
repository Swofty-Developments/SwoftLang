import "./mod/coll_a.sw"
import "./mod/coll_b.sw"

command "which" {
    execute {
        send shared_name() to sender
    }
}
