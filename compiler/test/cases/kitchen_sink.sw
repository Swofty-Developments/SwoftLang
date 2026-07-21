// kitchen sink: exercises every statement and expression kind
/* block comment
   spanning multiple lines */

function add(a: Integer, b: Integer) {
    return a + b
}

function fact(n: int) {
    if n <= 1 {
        return 1
    }
    return n * fact(n - 1)
}

function greet(p) {
    send "Hi ${p}" to p
    return
}

command "sink", "s" {
    permission: "swoftlang.sink"
    description: "Exercises everything"

    arguments {
        who: Player = sender
        where: either<Player|Location>
        depth: either<either<Integer|Double>|String> = 3
        note: String = "none"
        flag: bool = true
        mystery: Wobble
    }

    execute {
        set x to 1 + 2 * 3
        set y to (1 + 2) * 3
        set z to -x + 4.5 % 2
        set w to 10 / 2 - 3
        set neg to -(x + y)
        set dneg to - -x
        set dnot to not not flag
        set a to true
        set b to false
        set c to true
        set both to not a and b
        set either_way to a or b and not c
        set sym to a && b || c
        set cmp to x < 2 and x > 1 and x <= 3 and x >= 0
        set eqs to x == 1 or x = 2 or x != 3
        set iseq to args.depth is 5
        set isneq to args.depth is not 5
        set check to args.who is a Player
        set check2 to args.where is an Entity
        set nocheck to args.who is not an Entity
        set msg to "so bad"
        set within to msg contains "bad"
        set truth to true
        set lie to false
        if x = 1 {
            send "one"
        } else if x = 2 {
            send "two" to sender
        } else {
            send "many" to all
        }
        {
            set inner to true
        }
        send "everyone" to all players
        broadcast "big news"
        teleport args.who to args.where
        loop 3 times {
            broadcast "tick"
        }
        loop x + 1 times as i {
            send "i = ${i}" to sender
        }
        loop all players as p {
            send "hello" to p
        }
        while x < 10 {
            set x to x + 1
        }
        greet(sender)
        call greet(args.who)
        set r to add(1, 2) + fact(3)
        set n to length("abc")
        if false {
            halt
        }
        halt
    }
}

Player {
    on_chat {
        if message contains "badword" {
            cancel event
        }
        return
    }
}
