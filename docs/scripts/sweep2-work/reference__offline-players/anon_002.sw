function describe(subject: OfflinePlayer) {
    if subject is a Player {
        send "you are online right now" to subject
    }
}
