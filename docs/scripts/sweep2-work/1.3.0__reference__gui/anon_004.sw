gui "clicky" {
    rows: 1
    title: "Clicky"
    state { page: 0, enabled: true }

    slot 4 {
        item { material: "DIAMOND", name: "<green>Button", glint: state.enabled }
        on_click(right) {
            set state.enabled to false        // state write -> re-render
        }
        on_click {
            set state.page to state.page + 1  // any other click
        }
        refresh: 1 seconds
    }
}
