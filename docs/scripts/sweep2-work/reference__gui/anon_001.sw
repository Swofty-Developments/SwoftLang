gui "hello" {
    rows: 1
    title: "Hello"

    slot 4 {
        item { material: "DIAMOND", name: "<green>Click me" }
        on_click {
            send "clicked!" to player
        }
    }
}

command "hello-gui" {
    execute {
        open gui "hello" to sender
    }
}
