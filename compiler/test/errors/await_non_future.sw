async function foo(p: Player) {
    set x to await p
    send "x = ${x}" to p
}
