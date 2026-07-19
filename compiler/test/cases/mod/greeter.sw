// imported library: exported symbols are visible to importers, private ones
// are not; an optional return type flows across the module boundary

function decorate(name: String) {
    return "[${name}]"
}

export function greet(name: String) {
    return "hello ${decorate(name)}"
}

export function find_greeting(name: String) {
    if name is "steve" {
        return greet(name)
    }
}
