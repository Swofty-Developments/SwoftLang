// first-class inline functions + brace-free bodies, exercised end to end
// by the headless harness (ExecHarness prints every send as [OUT])

// brace-free function body
function triple(x: Integer) return x * 3

// higher-order: applies a passed-in callable
function apply(f, v) {
    return f(v)
}

command "lambdas" {
    execute {
        // call through a variable
        set double to function(x: Integer) return x * 2
        send "double(4) = ${double(4)}" to sender
        send "triple(5) = ${triple(5)}" to sender

        // closure counter: capture is by reference, mutation is shared
        set count to 0
        set inc to function() set count to count + 1
        inc()
        inc()
        send "count after two inc() = ${count}" to sender

        // higher-order pass and return
        send "apply(double, 10) = ${apply(double, 10)}" to sender
        set make_adder to function(n: Integer) return function(x: Integer) return x + n
        set add5 to make_adder(5)
        send "add5(3) = ${add5(3)}" to sender

        // recursion through a callable variable (none-seeded so the body
        // can reference the name it is being assigned to)
        set fact to none
        set fact to function(n: Integer) {
            if n <= 1 return 1
            return n * fact(n - 1)
        }
        send "fact(10) = ${fact(10)}" to sender

        // callables print sanely
        send "double is ${double}" to sender

        // brace-free if
        if count = 2 send "brace-free if works" to sender

        // async lambda spawned from sync color
        set task to async function(msg: String) {
            wait 1 ticks
            send "async lambda ran: ${msg}" to sender
        }
        spawn task("hello")
    }
}
