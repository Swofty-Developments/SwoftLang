// first-class inline functions: lambda values, closures, higher-order use

// returns a lambda that closes over its parameter
function make_adder(n: Integer) {
    return function(x: Integer) return x + n
}

// higher-order: takes a callable and applies it
function apply(f, v) {
    return f(v)
}

command "lambdas" {
    execute {
        // lambda stored in a variable, called through the variable
        set double to function(x: Integer) return x * 2
        send "double(4) = ${double(4)}" to sender

        // brace-free and braced bodies
        set shout to function(s: String) {
            return uppercase(s)
        }
        send shout("hey") to sender

        // closure capture is by reference: inc mutates the shared count
        set count to 0
        set inc to function() set count to count + 1
        inc()
        inc()
        send "count = ${count}" to sender

        // higher-order pass and return
        send "apply(double, 10) = ${apply(double, 10)}" to sender
        set add5 to make_adder(5)
        send "add5(3) = ${add5(3)}" to sender

        // async lambda: spawn through the variable is legal in sync color
        set task to async function(msg: String) {
            wait 1 ticks
            send "later: ${msg}" to sender
        }
        spawn task("hello")

        // a callable renders as <function(N params)>
        send "value: ${double}" to sender
    }
}
