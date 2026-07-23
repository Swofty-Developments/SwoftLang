async function prepare(p: Player) {
    set greeting to async {
        wait 200 millis
        "Welcome back"        // trailing expression → Future<String>
    }
    send "<gray>..." to p
    send await greeting to p
}
