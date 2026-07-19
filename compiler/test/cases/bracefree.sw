// brace-free single-statement bodies in every position that takes a body

// function body
function double(x: Integer) return x * 2

// async function body
async function tick() wait 1 ticks

command "bracefree" {
    arguments {
        n: Integer
    }
    // execute body itself
    execute send "double = ${double(args.n)}" to sender
}

command "forms" {
    execute {
        // if / else if / else bodies
        if 1 > 2 send "impossible" to sender
        else if 2 > 3 halt
        else send "sane" to sender

        // loop / while / foreach bodies
        loop 3 times as i send "i = ${i}" to sender
        set n to 0
        while n < 3 set n to n + 1
        loop [1, 2, 3] as item send "item = ${item}" to sender

        // async block body
        async send "from async" to sender

        // dangling else binds to the nearest if: this else belongs to the
        // inner if, so the outer if has no else branch
        if 1 > 0 if 2 > 3 send "inner then" to sender
        else send "inner else" to sender
    }
}

gui "quick" {
    rows: 1
    title: "Quick"
    slot 0 {
        item {
            material: "stone"
        }
        // slot click handler body
        on_click (left) send "clicked" to player
    }
    editable [8] {
        // editable change handler body
        on_change send "changed slot ${slot}" to player
    }
    // gui handler bodies
    on_open send "opened" to player
    on_close send "closed (${reason})" to player
    on_click send "fallback ${slot}" to player
}
