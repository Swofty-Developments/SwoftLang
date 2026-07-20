command "loaders" {
    execute {
        load world "a" with anvil_loader("worlds")
        load world "b" with polar_loader("worlds")
        load world "c" with polar_storage_loader(files "data/worlds")
    }
}
