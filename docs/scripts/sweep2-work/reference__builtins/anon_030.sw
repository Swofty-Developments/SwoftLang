command "rename" {
    execute async {
        set answer to prompt_input(sender, "new name?")
        set sender.display_name to answer
        send "<lime>Renamed to ${answer}" to sender
    }
}
