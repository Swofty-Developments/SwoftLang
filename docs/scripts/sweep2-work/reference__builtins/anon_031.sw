command "wear" {
    execute async {
        set s to fetch_skin("Notch")
        if s exists {
            set sender.skin to s
        }
    }
}
