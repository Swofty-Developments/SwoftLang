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
