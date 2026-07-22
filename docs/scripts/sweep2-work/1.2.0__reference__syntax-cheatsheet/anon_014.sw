import "music"                           // stdlib/addon by name (addon path)
                                         // import "./lib/util.sw" — relative form

var greeting_count = 0                   // module-level var: private, shared state

export function greet(target: Player) {  // 'export' makes it importable
    set greeting_count to greeting_count + 1
    send "hello (#${greeting_count})" to target
}

function helper() return 1               // un-exported = private to this file
