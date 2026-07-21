---
title: Functions & Lambdas
---

<StepHeader>
reusable typed functions, a recursive <code>fib</code>, and first-class lambdas — every call site checked before boot.
</StepHeader>

Declare functions at the top level of any script, alongside your commands and events:

```swoftlang
function double(n: Integer) {
    return n * 2
}

function announce(p: Player, text: String) {
    send "<gold>${text}" to p
}

command "demo" {
    execute {
        send "double(21) = ${double(21)}"
        announce(sender, "functions work")
    }
}
```

Functions declared in one script are callable from every other script — they land in one
global registry at load time. (Making a function *private* to a module is
[Step 13](/1.1.0/guide/modules).)

<MappedCompare>
<MappedPair label="a reward function">
<template #skript>

```skript
function reward(target: player, amount: integer):
    send "&6You earned %{_amount}% coins" to {_target}

command /payday:
    trigger:
        reward(player, 250)
```

</template>
<template #swoftlang>

```swoftlang
function reward(target: Player, amount: Integer) {
    send "<gold>You earned ${amount} coins" to target
}

command "payday" {
    execute {
        if sender is a Player {
            reward(sender, 250)
        }
    }
}
```

</template>
<template #note>

Same idea, but parameters are ordinary names (no `{_braces}`), types are capitalized,
and calls are checked: wrong arity or a `String` where a `Player` belongs is a compile
error. The `is a Player` guard is required because `sender` can be the console — the
compiler won't let you pass a maybe-console value into a `Player` parameter.

</template>
</MappedPair>
</MappedCompare>

## Parameters

Parameters are typed with the same types as command arguments — `n: Integer`,
`p: Player`, `dest: either<Player|Location>`. Untyped parameters are `Any` and checked
dynamically. The annotations aren't decoration: the checker verifies every call site
against them, and verifies the *body* uses each parameter consistently with its type.

Arguments are evaluated at the call site and bound in a fresh scope. Reassigning a
parameter inside a function never leaks out — though mutating a *shared object* (say,
setting `p.health`) is visible everywhere, because there's one player.

Get a call wrong and the compiler tells you before the server boots:

<!-- swoftc name=demo.sw expect=error -->

```swoftlang
function double(n: Integer) {
    return n * 2
}

command "demo" {
    execute {
        send "${double(2, 3)}" to sender
    }
}
```

```txt
demo.sw:7:14: error: function 'double' expects 1 argument(s), got 2
        send "${double(2, 3)}" to sender
             ^
```

Unknown names get the same treatment — `unknown function 'trible'`, pointing at the call.

## `return`

`return <expr>` exits the function with a value; bare `return` exits without one. At the
top level of a command or event body, `return` just ends the run (same as `halt`).

Return types are inferred. If *some* paths return a value and others fall off the end,
callers get an `optional<T>` and must handle the missing case — that's not a lint, it's
the type system, and it's [Step 07](/1.1.0/guide/options#functions-that-might-not-return-a-value).

## Recursion

```swoftlang
function fib(n: Integer) {
    if n <= 1 {
        return n
    }
    return fib(n - 1) + fib(n - 2)
}

command "fib" {
    execute {
        send "fib(10) = ${fib(10)}"
    }
}
```

::: warning Depth cap
Recursion depth is capped at **256** frames at runtime — deep enough for real work,
shallow enough that an accidental infinite recursion produces a script error citing your
source line rather than exhausting the stack.
:::

## Statement calls and `call`

A function call can stand alone as a statement; any returned value is discarded. The
`call` keyword is optional and purely cosmetic:

```swoftlang
function greet(p: Player) {
    send "Welcome, ${p}!" to p
}

command "greet" {
    execute {
        greet(sender)
        call greet(sender)
    }
}
```

Both lines do the same thing. Use whichever reads better to you.

## Inline functions (lambdas) {#inline-functions-lambdas}

`function(...)` without a name is an *expression* that evaluates to a function value.
Store it in a variable, pass it to a function, return it from one, and call it through
whatever name holds it:

```swoftlang
function apply(f, v) {
    return f(v)
}

command "inline" {
    execute {
        set double to function(x: Integer) return x * 2
        send "double(4) = ${double(4)}" to sender                  // 8
        send "apply(double, 10) = ${apply(double, 10)}" to sender  // 20

        set make_adder to function(n: Integer) return function(x: Integer) return x + n
        set add5 to make_adder(5)
        send "add5(3) = ${add5(3)}" to sender                      // 8
    }
}
```

(That one-line `function(x: Integer) return x * 2` uses the
[brace-free body form](/1.1.0/guide/control-flow#brace-free-bodies) from Step 05.)

The checker knows the shape of a lambda-typed variable: it verifies arity and parameter
types at every call through the variable, and infers the return type just like a named
function. An `Any`-typed callee (say, a lambda that arrived through an untyped
parameter) is checked dynamically at runtime instead. Skript has no equivalent — its
functions are only ever called by name; lambdas are what make the addon-style APIs in
[Step 13](/1.1.0/guide/modules#lambdas-across-modules) possible.

### Closures capture by reference

A lambda body reads and writes the environment it was defined in — the *same*
variables, not a copy:

```swoftlang
command "counter" {
    execute {
        set count to 0
        set inc to function() set count to count + 1
        inc()
        inc()
        send "count = ${count}" to sender     // 2 — the lambda mutates the shared variable
    }
}
```

Two subtleties worth knowing: a lambda defined inside a loop captures the loop
variable's single shared slot, not the value at that iteration (copy it into its own
variable first if the lambda should remember it); and optional-narrowing from
[Step 07](/1.1.0/guide/options) does not survive into a lambda body — the body may run long
after the check, so re-check or use `otherwise` inside.

### Async lambdas

`async function(...)` gives a lambda the right to `wait`. The coloring rules
([Step 09](/1.1.0/guide/async)) match named functions: call it directly only from async code;
from sync code, `spawn` it through the variable:

```swoftlang
command "later" {
    execute {
        set task to async function(msg: String) {
            wait 1 seconds
            send "later: ${msg}" to sender
        }
        spawn task("hello")
        send "wait for it" to sender
    }
}
```

### How call names resolve

`name(args)` resolves in order: a local **variable holding a function value**, then
**declared functions**, then **builtins**. A variable holding a non-function never
shadows a call — `player("Notch")` still reaches the builtin inside an event that binds
`player`. Calling a value the checker knows isn't a function is a compile error
(`'x' is an Integer, not a function`).

Next: the feature the whole compiler is built around.
