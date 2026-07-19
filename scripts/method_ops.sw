// W-collections verification: exercises EVERY map / list / string method and
// every property-form accessor with KNOWN expected outputs. The headless
// harness prints each `send` as [OUT]; a driver asserts exact values. Nothing
// here is random (no shuffled/random_*), so every line is deterministic.
// Method results are bound to variables first because the string lexer ends a
// "..." literal at the first inner double-quote, so `${m.get("a")}` can't be
// written inline.

command "map_ops" {
    execute {
        // map<String,Integer>, insertion order b, a, c
        set m to { "b": 2, "a": 1, "c": 3 }

        // --- pure expression methods + accessors ---
        set r to m.get("a") otherwise 0
        send "m.get.hit ${r}" to sender                               // 1
        set r to m.get("z") otherwise -1
        send "m.get.miss ${r}" to sender                              // -1
        set r to m.has("a")
        send "m.has.true ${r}" to sender                              // true
        set r to m.has("z")
        send "m.has.false ${r}" to sender                             // false
        set r to m.get_or("a", 99)
        send "m.get_or.hit ${r}" to sender                            // 1
        set r to m.get_or("z", 99)
        send "m.get_or.miss ${r}" to sender                           // 99
        send "m.size ${m.size}" to sender                             // 3
        send "m.is_empty ${m.is_empty}" to sender                     // false
        set r to m.keys.joined(",")
        send "m.keys ${r}" to sender                                  // b,a,c
        set r to m.values.joined(",")
        send "m.values ${r}" to sender                                // 2,1,3

        // sorted transforms (pure): chain method -> .keys prop -> joined method
        set r to m.sorted_by_key().keys.joined(",")
        send "m.sbk ${r}" to sender                                   // a,b,c
        set r to m.sorted_by_key_desc().keys.joined(",")
        send "m.sbk_desc ${r}" to sender                              // c,b,a
        set r to m.sorted_by_value().keys.joined(",")
        send "m.sbv ${r}" to sender                                   // a,b,c
        set r to m.sorted_by_value_desc().keys.joined(",")
        send "m.sbv_desc ${r}" to sender                              // c,b,a
        set r to m.sorted_by(function(k, v) return v).keys.joined(",")
        send "m.sortby ${r}" to sender                                // a,b,c

        // proof sorting is PURE: original untouched
        set r to m.keys.joined(",")
        send "m.pure ${r}" to sender                                  // b,a,c

        // deprecated free-builtin map_get MUST equal the method
        set r to m.get("a") otherwise -1
        send "alias.method ${r}" to sender                            // 1
        set r to map_get(m, "a") otherwise -1
        send "alias.builtin ${r}" to sender                           // 1

        // --- mutating statement methods (live map) ---
        set mm to { "x": 1 }
        mm.set("y", 2)
        mm.set("x", 5)
        mm.delete("y")
        set r to mm.keys.joined(",")
        send "mm.after ${r}" to sender                                // x
        set r to mm.get("x") otherwise 0
        send "mm.x ${r}" to sender                                    // 5
        mm.clear()
        send "mm.cleared ${mm.is_empty}" to sender                    // true
        send "mm.size ${mm.size}" to sender                           // 0

        set p1 to { "a": 1 }
        set p2 to { "b": 2, "a": 9 }
        p1.put_all(p2)
        send "p1.size ${p1.size}" to sender                           // 2
        set r to p1.get("a") otherwise 0
        send "p1.a ${r}" to sender                                    // 9
    }
}

command "list_ops" {
    execute {
        set l to [3, 1, 2]

        // accessors + pure methods
        send "l.size ${l.size}" to sender                             // 3
        send "l.is_empty ${l.is_empty}" to sender                     // false
        send "l.first ${l.first otherwise -1}" to sender              // 3
        send "l.last ${l.last otherwise -1}" to sender                // 2
        set r to l.contains(1)
        send "l.contains.true ${r}" to sender                         // true
        set r to l.contains(9)
        send "l.contains.false ${r}" to sender                        // false
        set r to l.index_of(2) otherwise -1
        send "l.index_of.hit ${r}" to sender                          // 2
        set r to l.index_of(9) otherwise -1
        send "l.index_of.miss ${r}" to sender                         // -1
        set r to l.get(0) otherwise -1
        send "l.get.hit ${r}" to sender                               // 3
        set r to l.get(5) otherwise -1
        send "l.get.oob ${r}" to sender                               // -1
        send "l.count ${l.count(1)}" to sender                        // 1
        set r to l.joined("-")
        send "l.joined ${r}" to sender                                // 3-1-2
        set r to l.sorted().joined(",")
        send "l.sorted ${r}" to sender                                // 1,2,3
        set r to l.sorted_by(function(x) return x).joined(",")
        send "l.sortby ${r}" to sender                                // 1,2,3
        set r to l.sorted_by_desc(function(x) return x).joined(",")
        send "l.sortby_desc ${r}" to sender                           // 3,2,1
        set r to l.reversed().joined(",")
        send "l.reversed ${r}" to sender                              // 2,1,3
        set r to l.filtered(function(x) return x > 1).joined(",")
        send "l.filtered ${r}" to sender                              // 3,2
        set r to l.mapped(function(x) return x * 10).joined(",")
        send "l.mapped ${r}" to sender                                // 30,10,20
        set r to l.taken(2).joined(",")
        send "l.taken ${r}" to sender                                 // 3,1
        set r to l.dropped(2).joined(",")
        send "l.dropped ${r}" to sender                               // 2
        set r to l.min_by(function(x) return x) otherwise -1
        send "l.min_by ${r}" to sender                                // 1
        set r to l.max_by(function(x) return x) otherwise -1
        send "l.max_by ${r}" to sender                                // 3

        // proof pure methods do NOT mutate
        set r to l.joined(",")
        send "l.pure ${r}" to sender                                  // 3,1,2

        // --- mutation + ALIASING: b and a share ONE live object ---
        set a to [1, 2, 3]
        set b to a
        a.add(4)
        a.insert(0, 0)
        a.remove(2)
        a.remove_at(0)
        set r to a.joined(",")
        send "a.live ${r}" to sender                                  // 1,3,4
        set r to b.joined(",")
        send "b.alias ${r}" to sender                                 // 1,3,4
        send "b.alias.size ${b.size}" to sender                       // 3

        set c to [1]
        c.add_all([2, 3])
        set r to c.joined(",")
        send "c.add_all ${r}" to sender                               // 1,2,3
        a.clear()
        send "a.cleared ${a.is_empty}" to sender                      // true
    }
}

command "string_ops" {
    execute {
        set s to "Hello World"

        send "s.length.prop ${s.length}" to sender                    // 11
        send "s.length.method ${s.length()}" to sender                // 11
        set r to s.upper()
        send "s.upper ${r}" to sender                                 // HELLO WORLD
        set r to s.lower()
        send "s.lower ${r}" to sender                                 // hello world
        set r to "  hi  ".trimmed()
        send "s.trimmed [${r}]" to sender                             // [hi]
        set r to s.contains("World")
        send "s.contains.true ${r}" to sender                         // true
        set r to s.contains("xyz")
        send "s.contains.false ${r}" to sender                        // false
        set r to s.starts_with("Hello")
        send "s.starts ${r}" to sender                                // true
        set r to s.ends_with("World")
        send "s.ends ${r}" to sender                                  // true
        set r to s.replace("World", "There")
        send "s.replace ${r}" to sender                               // Hello There
        set r to s.split(" ").joined("|")
        send "s.split ${r}" to sender                                 // Hello|World
        set r to "a,,b".split(",").joined("|")
        send "s.split.empty.mid ${r}" to sender                       // a||b
        set r to "".split(",").size
        send "s.split.emptystr.size ${r}" to sender                   // 1
        set r to "abc".split("").joined("|")
        send "s.split.chars ${r}" to sender                           // a|b|c
        set r to s.substring(0, 5)
        send "s.substring ${r}" to sender                             // Hello
        set r to s.substring(6, 100)
        send "s.substring.oob ${r}" to sender                         // World
        set r to s.substring(20, 25)
        send "s.substring.past [${r}]" to sender                      // []
        set r to s.index_of("World") otherwise -1
        send "s.index_of.hit ${r}" to sender                          // 6
        set r to s.index_of("zzz") otherwise -1
        send "s.index_of.miss ${r}" to sender                         // -1
        set r to "ab".repeated(3)
        send "s.repeated ${r}" to sender                              // ababab
        set r to "abc".reversed()
        send "s.reversed ${r}" to sender                              // cba
        set r to "5".padded_left(3, "0")
        send "s.pad_left ${r}" to sender                              // 005
        set r to "5".padded_right(3, "0")
        send "s.pad_right ${r}" to sender                             // 500
    }
}

command "nested_and_stable" {
    execute {
        // nested map<Integer, list<String>>: get() yields optional<list<..>>,
        // unwrapped with 'otherwise', then list methods resolve on the element
        set nested to { 1: ["a", "b"], 2: ["c"] }
        set lst to nested.get(1) otherwise []
        send "nested.size ${lst.size}" to sender                      // 2
        set r to lst.joined(",")
        send "nested.joined ${r}" to sender                           // a,b
        set lst2 to nested.get(2) otherwise []
        set r to lst2.joined(",")
        send "nested.get2 ${r}" to sender                             // c
        send "nested.values.size ${nested.values.size}" to sender     // 2

        // sorted_by STABLE (asc + desc): equal keys keep input order
        set names to ["bb", "aa", "c"]
        set r to names.sorted_by(function(x) return x.length).joined(",")
        send "stable.asc ${r}" to sender                              // c,bb,aa
        set r to names.sorted_by_desc(function(x) return x.length).joined(",")
        send "stable.desc ${r}" to sender                             // bb,aa,c

        // min_by/max_by keep the FIRST element on a tie
        set r to names.max_by(function(x) return x.length) otherwise "?"
        send "stable.max ${r}" to sender                              // bb
        set r to names.min_by(function(x) return x.length) otherwise "?"
        send "stable.min ${r}" to sender                              // c

        // map sorted_by_value STABLE: two equal values keep insertion order
        set tie to { "b": 1, "a": 1, "c": 2 }
        set r to tie.sorted_by_value().keys.joined(",")
        send "map.stable ${r}" to sender                              // b,a,c
    }
}
