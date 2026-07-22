command "cloudworlds" {
    execute {
        load world "skyblock_1" with polar_storage_loader(mysql {
            host: "localhost"
            database: "mc"
            user: "root"
            password: "hunter2"
        })
        load world "skyblock_2" with polar_storage_loader(files "data/worlds")
    }
}
