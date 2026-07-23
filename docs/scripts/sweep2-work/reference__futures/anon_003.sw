async function demo(p: Player) {
    set answer to async {
        wait 200 millis
        6 * 7           // trailing expression → Future<Integer>
    }
    send "answer ${await answer}" to p
}
