// v1.10.0 §3.2: an OfflinePlayer may be owned by another server, so a plain
// assignment would clobber that server's copy.
storage {
    backend: mysql { host: "db", database: "net", user: "mc", password: "p" }
    mode: network
}

persistent coins for Player: Integer = 0

function pay(who: OfflinePlayer) {
    set coins for who to 100
}
