// W-stdlib: the P0/P1 standard-library surface a compiled clone usually lacks.
// Exercises the genuine-gap builtins added by the stdlib audit — math beyond
// arithmetic, the design-named random forms, color/format helpers, string free
// helpers, number formatting, and location/vector math — plus the new String
// methods (first_chars/last_chars) and Vec props (.length/.normalized).

command "stdlib" {
    execute {
        // --- B3 math (java.lang.Math) ---
        set m to mod(10, 3)
        set r to round_to(3.14159, 2)
        set s to sqrt(16.0)
        set p to pow(2, 10)
        set sg to sign(0 - 5)
        set trig to sin(0.0) + cos(0.0) + tan(0.0)
        set inv to asin(0.0) + acos(1.0) + atan(0.0) + atan2(1.0, 1.0)
        set logs to ln(e()) + log10(100.0) + log(8.0, 2.0)
        set circ to pi()
        set total to sum([1, 2, 3, 4])
        set prod to product([1, 2, 3, 4])
        send "m ${m} r ${r} s ${s} p ${p} sg ${sg}" to sender
        send "trig ${trig} inv ${inv} logs ${logs} circ ${circ}" to sender
        send "sum ${total} product ${prod}" to sender

        // --- B4 random (design-named forms + aliases) ---
        random_seed(42)
        set die to random_int(1, 6)
        set rd to random_double(0.0, 1.0)
        if chance(0.5) {
            send "coin" to sender
        }
        set loot to ["sword", "shield", "potion"]
        set drop to random_element(loot) otherwise "nothing"
        set id to random_uuid()
        send "die ${die} rd ${rd} drop ${drop} id ${id}" to sender

        // --- B1 string free helpers + new string methods ---
        set n to parse("42", Integer) otherwise 0
        set ok to matches("abc123", "[a-z0-9]+")
        set bare to stripped("&aHello")
        set fmt to formatted("&aHello")
        set head to "Hello, World".first_chars(5)
        set tail to "Hello, World".last_chars(5)
        send "n ${n} ok ${ok} bare ${bare} fmt ${fmt}" to sender
        send "head ${head} tail ${tail}" to sender

        // --- B2 color & format codes ---
        set nocol to strip_color("&aGreen &lBold")
        set mini to legacy_to_mini("&aGreen")
        set grad to gradient("Rainbow", "#ff0000", "#0000ff")
        set rain to rainbow("Party")
        send "${nocol} ${mini} ${grad} ${rain}" to sender

        // --- B8 number formatting ---
        set thousands to format_number(1234567)
        set places to format_decimals(3.14159, 2)
        send "thousands ${thousands} places ${places}" to sender

        // --- B6 type reflection ---
        set tn to type_of(die)
        send "type ${tn}" to sender

        // --- B7 location / region / vector math ---
        set here to location_of(sender)
        set up to above(here, 2)
        set down to below(here, 1)
        set d to distance(here, up)
        set inside to is_within(here, down, up)
        set dir to direction_from(here, up)
        set nearby to blocks_in_radius(here, 3)
        set folks to players_in_radius(here, 8)
        set v to vec(3.0, 4.0, 0.0)
        set len to v.length
        set unit to v.normalized
        send "d ${d} inside ${inside} nearby ${nearby.size} folks ${folks.size}" to sender
        send "len ${len} unit ${unit.x} dirx ${dir.x}" to sender
    }
}
