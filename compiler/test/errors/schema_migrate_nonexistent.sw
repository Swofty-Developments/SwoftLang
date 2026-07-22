// A migrate block may only target a version <= the struct's schema.
struct Guild {
    schema: 2
    name: String
    tag: String = ""

    migrate to 3 {
        set tag to ""
    }
}
