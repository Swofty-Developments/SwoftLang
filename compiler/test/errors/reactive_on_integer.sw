// §4: @EventReceiver on a field whose type has no receiver vocabulary is an error
struct Counter {
    @EventReceiver count: Integer
}
