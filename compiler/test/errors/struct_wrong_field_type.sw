struct Point {
    x: Integer
    y: Integer
}

function make() {
    set p to Point { x: "hello", y: 2 }
    send "${p.x}" to sender
}
