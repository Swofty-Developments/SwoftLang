struct Point {
    x: Integer
    y: Integer
}

function make() {
    set p to Point { x: 1, y: 2, z: 3 }
    send "${p.x}" to sender
}
