// module-level vars: private, non-persistent, initialized at load in
// declaration order (base is visible to the step initializer)
var base = 5
var step = base + 1
var owner = "nobody"

export function advance() {
    set base to base + step
    return base
}

export function claim(name: String) {
    set owner to name
}

export function describe() {
    return "base=${base} owner=${owner}"
}
