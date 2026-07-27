// v1.10.0 §3.2: a read-modify-write of a replicated global loses updates when
// two servers do it at once.
storage {
    backend: mongodb "mongodb://db/net"
    mode: network
}

persistent pot: Integer = 0

command "bet" {
    execute {
        set pot to pot + 50
    }
}
