// Player.on_chat binds exactly one argument (message); a second binder is an
// arity error.
Player {
    on_chat(message, extra) {
        broadcast "hi"
    }
}
