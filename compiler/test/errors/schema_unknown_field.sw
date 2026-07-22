// A migrate block may only assign the current struct's fields.
struct Guild {
    schema: 2
    name: String

    migrate to 2 {
        set nickname to "anon"
    }
}
