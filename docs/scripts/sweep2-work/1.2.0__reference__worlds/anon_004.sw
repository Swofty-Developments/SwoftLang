command "migrate" {
    execute {
        import anvil world "vanilla/world" as "hub" with polar_storage_loader(files "data/worlds")
    }
}
