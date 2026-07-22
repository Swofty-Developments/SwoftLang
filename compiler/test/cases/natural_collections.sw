// Natural-language dialect for collection operations. Every form here coexists
// with the method dialect (m.set/.get/.has/.delete, l.add/.remove/.sorted, ...)
// and desugars to the SAME emit node: the map_* / prop / method / sort builtins.

command "natural" {
    execute {
        // --- maps ---
        set scores to { "alice": 10, "bob": 25 }

        // write (existing sugar) + index read (existing sugar, Optional<V>)
        set scores at "carol" to 7
        set a to scores["alice"] otherwise 0
        send "alice ${a}" to sender

        // 'm has k' -> Boolean membership
        if scores has "bob" {
            send "has bob" to sender
        }

        // 'size of m', 'keys of m' (List<K>), 'values of m' (List<V>)
        send "size ${size of scores}" to sender
        loop keys of scores as k {
            send "key ${k}" to sender
        }
        loop values of scores as amount {
            send "val ${amount}" to sender
        }

        // 'delete m at k' then 'clear m'
        delete scores at "bob"
        clear scores

        // --- lists ---
        set nums to [3, 1, 2]

        // 'add x to l' / 'remove x from l' / 'l contains x' (existing)
        add 4 to nums
        remove 1 from nums
        if nums contains 2 {
            send "has two" to sender
        }

        // 'size of l', 'sorted l', 'sorted l by <lambda>', 'reversed l'
        send "count ${size of nums}" to sender
        set asc to sorted nums
        set ranked to sorted nums by function(n) return n
        set rev to reversed nums
        send "sizes ${size of asc} ${size of ranked} ${size of rev}" to sender

        // 'first of l' / 'last of l' -> Optional<T>
        set hd to first of nums otherwise 0
        set tl to last of nums otherwise 0
        send "hd ${hd} tl ${tl}" to sender

        // 'clear l'
        clear nums

        // --- strings ---
        set name to "SwoftLang"
        send "up ${uppercase of name}" to sender
        send "down ${lowercase of name}" to sender
        send "len ${length of name}" to sender
    }
}
