// rbtree.sw — a real red-black tree in pure SwoftLang.
//
// No Java, no engine internals: a node is a map<Any, Any> with the fields
//   "id"     Integer  — a unique identity (maps have no reference-equality op)
//   "value"  Integer  — the key
//   "red"    Boolean  — colour (true = red, false = black)
//   "left"/"right"/"parent"  — child/parent nodes, ABSENT when nil
//
// There is no null in the language, so a missing child is simply an absent
// map key; we reach for it with the m[k] index-read (optional<Any>) and prove
// presence with `exists` / `is missing` before use. The tree itself lives in a
// holder map `t` with keys "root" (absent when empty) and "next_id".
//
// INSERT is the textbook CLRS algorithm: BST descent, then an iterative
// fix-up with explicit LEFT-ROTATE / RIGHT-ROTATE and the recolour cases.

// ---------------------------------------------------------------------------
// Node + tree construction
// ---------------------------------------------------------------------------

function new_tree() {
    set t to new_map()
    set t at "next_id" to 1
    return t
}

function new_node(t, v) {
    set id to t["next_id"] otherwise 1
    set t at "next_id" to id + 1
    set n to new_map()
    set n at "id" to id
    set n at "value" to v
    set n at "red" to true         // new nodes start red
    return n
}

// Identity: two nodes are the same iff their ids match (maps have no `is` op).
function same(a, b) {
    set ai to a["id"] otherwise 0 - 1
    set bi to b["id"] otherwise 0 - 2
    return ai == bi
}

// Is x its parent's LEFT child?  Precondition: x has a parent.
function is_left(x) {
    set popt to x["parent"]
    if popt is missing {
        return false
    }
    set p to popt
    set pl to p["left"]
    if pl exists {
        return same(pl, x)
    }
    return false
}

// Colour of a possibly-absent child (nil counts as black).
function child_is_red(node, key) {
    set c to node[key]
    if c is missing {
        return false
    }
    set cc to c
    return cc["red"] otherwise false
}

// ---------------------------------------------------------------------------
// Rotations
// ---------------------------------------------------------------------------

function left_rotate(t, x) {
    set yopt to x["right"]
    if yopt is missing {
        return                       // precondition: right child exists
    }
    set y to yopt

    // x.right becomes y.left
    set yl to y["left"]
    if yl exists {
        set x at "right" to yl
        set yl at "parent" to x
    } else {
        delete x at "right"
    }

    // y takes x's place under x's parent
    set xpopt to x["parent"]
    if xpopt exists {
        set xp to xpopt
        set y at "parent" to xp
        if is_left(x) {
            set xp at "left" to y
        } else {
            set xp at "right" to y
        }
    } else {
        delete y at "parent"
        set t at "root" to y
    }

    // x hangs on y's left
    set y at "left" to x
    set x at "parent" to y
}

function right_rotate(t, x) {
    set yopt to x["left"]
    if yopt is missing {
        return                       // precondition: left child exists
    }
    set y to yopt

    // x.left becomes y.right
    set yr to y["right"]
    if yr exists {
        set x at "left" to yr
        set yr at "parent" to x
    } else {
        delete x at "left"
    }

    // y takes x's place under x's parent
    set xpopt to x["parent"]
    if xpopt exists {
        set xp to xpopt
        set y at "parent" to xp
        if is_left(x) {
            set xp at "left" to y
        } else {
            set xp at "right" to y
        }
    } else {
        delete y at "parent"
        set t at "root" to y
    }

    // x hangs on y's right
    set y at "right" to x
    set x at "parent" to y
}

// ---------------------------------------------------------------------------
// Insert + fix-up
// ---------------------------------------------------------------------------

function parent_is_red(z) {
    set popt to z["parent"]
    if popt is missing {
        return false
    }
    set p to popt
    return p["red"] otherwise false
}

function insert_fixup(t, z) {
    while parent_is_red(z) {
        set popt to z["parent"]
        if popt is missing {
            return                   // unreachable: parent_is_red guaranteed it
        }
        set p to popt
        set gopt to p["parent"]
        if gopt is missing {
            return                   // unreachable: a red p is never the root
        }
        set g to gopt

        if is_left(p) {
            // uncle is g.right
            if child_is_red(g, "right") {
                // Case 1: recolour and climb
                set uopt to g["right"]
                if uopt is missing {
                    return
                }
                set u to uopt
                set p at "red" to false
                set u at "red" to false
                set g at "red" to true
                set z to g
            } else {
                if not is_left(z) {
                    // Case 2: left-rotate into a line
                    set z to p
                    left_rotate(t, z)
                    set p2 to z["parent"]
                    if p2 is missing {
                        return
                    }
                    set p to p2
                    set g2 to p["parent"]
                    if g2 is missing {
                        return
                    }
                    set g to g2
                }
                // Case 3: recolour + right-rotate the grandparent
                set p at "red" to false
                set g at "red" to true
                right_rotate(t, g)
            }
        } else {
            // mirror image: uncle is g.left
            if child_is_red(g, "left") {
                set uopt to g["left"]
                if uopt is missing {
                    return
                }
                set u to uopt
                set p at "red" to false
                set u at "red" to false
                set g at "red" to true
                set z to g
            } else {
                if is_left(z) {
                    set z to p
                    right_rotate(t, z)
                    set p2 to z["parent"]
                    if p2 is missing {
                        return
                    }
                    set p to p2
                    set g2 to p["parent"]
                    if g2 is missing {
                        return
                    }
                    set g to g2
                }
                set p at "red" to false
                set g at "red" to true
                left_rotate(t, g)
            }
        }
    }
    // the root is always black
    set ropt to t["root"]
    if ropt exists {
        set root to ropt
        set root at "red" to false
    }
}

function tree_insert(t, v) {
    set z to new_node(t, v)

    set ropt to t["root"]
    if ropt is missing {
        set z at "red" to false
        set t at "root" to z
        return
    }

    // BST descent to find z's parent
    set cur to ropt
    set parent to ropt
    set searching to true
    while searching {
        set parent to cur
        set cv to cur["value"] otherwise 0
        if v < cv {
            set nx to cur["left"]
            if nx exists {
                set cur to nx
            } else {
                set searching to false
            }
        } else if v > cv {
            set nx to cur["right"]
            if nx exists {
                set cur to nx
            } else {
                set searching to false
            }
        } else {
            return                    // duplicate key: ignore
        }
    }

    set z at "parent" to parent
    set pv to parent["value"] otherwise 0
    if v < pv {
        set parent at "left" to z
    } else {
        set parent at "right" to z
    }

    insert_fixup(t, z)
}

// ---------------------------------------------------------------------------
// In-order traversal -> list of values
// ---------------------------------------------------------------------------

function inorder(node, acc) {
    set l to node["left"]
    if l exists {
        inorder(l, acc)
    }
    set v to node["value"] otherwise 0
    acc.add(v)
    set r to node["right"]
    if r exists {
        inorder(r, acc)
    }
}

// ---------------------------------------------------------------------------
// Invariant checks
// ---------------------------------------------------------------------------

// (a) no red node has a red child
function check_no_red_red(node) {
    set ok to true
    set red to node["red"] otherwise false

    set l to node["left"]
    if l exists {
        set lred to l["red"] otherwise false
        if red and lred {
            set ok to false
        }
        set sub to check_no_red_red(l)
        if not sub {
            set ok to false
        }
    }

    set r to node["right"]
    if r exists {
        set rred to r["red"] otherwise false
        if red and rred {
            set ok to false
        }
        set sub2 to check_no_red_red(r)
        if not sub2 {
            set ok to false
        }
    }
    return ok
}

// (b) every root-to-nil path has the same number of black nodes.
// Returns the black-height, or -1 if the two subtrees disagree.
function bh_of_child(node, key) {
    set c to node[key]
    if c is missing {
        return 1                     // a nil leaf is black
    }
    set cc to c
    return black_height(cc)
}

function black_height(node) {
    set lbh to bh_of_child(node, "left")
    set rbh to bh_of_child(node, "right")
    if lbh < 0 {
        return 0 - 1
    }
    if rbh < 0 {
        return 0 - 1
    }
    if lbh != rbh {
        return 0 - 1
    }
    set red to node["red"] otherwise false
    set blk to 1
    if red {
        set blk to 0
    }
    return lbh + blk
}

// ---------------------------------------------------------------------------
// Driver
// ---------------------------------------------------------------------------

command "rbtest" {
    execute {
        set t to new_tree()

        set input to [10, 20, 30, 15, 5, 25, 1, 8, 40, 35]
        loop input as v {
            tree_insert(t, v)
        }

        // in-order traversal
        set values to []
        set ropt to t["root"]
        if ropt exists {
            set root to ropt
            inorder(root, values)
        }

        set joined to values.joined(", ")
        send "in-order: ${joined}" to sender

        // sortedness
        set sorted_ok to true
        set n to values.size
        set i to 1
        while i < n {
            set a to values.get(i - 1) otherwise 0
            set b to values.get(i) otherwise 0
            if a > b {
                set sorted_ok to false
            }
            set i to i + 1
        }
        set count_ok to n == input.size

        // invariants
        set rr_ok to true
        set bh_ok to true
        set root_black to true
        if ropt exists {
            set root2 to ropt
            set rr_ok to check_no_red_red(root2)
            set bh to black_height(root2)
            if bh < 0 {
                set bh_ok to false
            }
            set root_black to not (root2["red"] otherwise false)
            send "black-height of root: ${bh}" to sender
        }

        // report
        set s_sorted to "FAIL"
        if sorted_ok and count_ok {
            set s_sorted to "PASS"
        }
        set s_rr to "FAIL"
        if rr_ok {
            set s_rr to "PASS"
        }
        set s_bh to "FAIL"
        if bh_ok {
            set s_bh to "PASS"
        }
        set s_root to "FAIL"
        if root_black {
            set s_root to "PASS"
        }

        send "[${s_sorted}] in-order output is sorted (${n} elements)" to sender
        send "[${s_root}] root is black" to sender
        send "[${s_rr}] invariant (a): no red node has a red child" to sender
        send "[${s_bh}] invariant (b): uniform black-height on all paths" to sender

        set all_ok to sorted_ok and count_ok and rr_ok and bh_ok and root_black
        if all_ok {
            send "RESULT: PASS — a valid red-black tree" to sender
        } else {
            send "RESULT: FAIL" to sender
        }
    }
}
