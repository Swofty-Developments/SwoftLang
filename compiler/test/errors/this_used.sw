// 'this' was removed: the receiver instance is a bare variable named after its
// type (here 'player').
Player {
    on_join {
        broadcast "${this.name}"
    }
}
