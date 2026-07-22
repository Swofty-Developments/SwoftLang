command "lists" {
    execute {
        set words to ["alpha", "beta", "gamma"]
        send "we have ${length(words)} words"
        loop words as w {
            send "word: ${w}"
        }
        loop all_players() as p {
            send "online: ${p.name}"
        }
    }
}
