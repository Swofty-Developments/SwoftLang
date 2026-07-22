gui "counter" {
    rows: 1
    title: "Clicked ${state.clicks} times"

    state {
        clicks: 0
    }

    slot 4 {
        item {
            material: "EMERALD"
            name: "<green>${state.clicks} clicks"
            glint: state.clicks > 0
        }
        on_click {
            set state.clicks to state.clicks + 1
        }
    }
}

command "counter" {
    execute {
        open gui "counter" to sender with { clicks: 0 }
    }
}
