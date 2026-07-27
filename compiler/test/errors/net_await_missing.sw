// v1.10.0 §3.1: a remote read is a Future<T> and has to be awaited.
storage {
    backend: mysql { host: "db", database: "net", user: "mc", password: "p" }
    mode: network
}

persistent coins for Player: Integer = 0

function report(who: OfflinePlayer) {
    async {
        set bal to coins for who
        broadcast "balance ${bal}"
    }
}
