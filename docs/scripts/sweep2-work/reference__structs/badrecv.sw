struct Score {
    @EventReceiver total: Integer
    total {
        on_death { broadcast "x" }
    }
}
