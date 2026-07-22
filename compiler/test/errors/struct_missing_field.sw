struct Point {
    x: Integer
    y: Integer
}

function make() {
    set p to Point { x: 1 }
    send "${p.x}" to sender
}
