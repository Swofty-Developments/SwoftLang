command "props" {
    description: "Property chains on the harness TestThing fixture"

    arguments {
        thing: Thing
    }

    execute {
        send "start: ${thing}"
        send "name = ${thing.name}"

        // plain setter hops on a mutable anchor
        set thing.name to "gizmo"
        set thing.score to thing.score + 5
        send "renamed: ${thing.name} score ${thing.score}"

        // wither hop past the anchor: read point, apply withX, store back
        set thing.point.x to 9.5
        send "point after wither write: ${thing.point}"
        set thing.point.y to thing.point.x + 0.25
        send "moved: ${thing}"

        // local-variable anchor: the wither result lands in the local only
        set p to thing.point
        set p.x to 0.5
        send "local point = ${p}"
        send "thing untouched by local write: ${thing.point}"
    }
}
