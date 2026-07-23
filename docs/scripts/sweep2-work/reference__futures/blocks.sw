// =========================================================================
// blocks.sw — vanilla block placement rules, written in SwoftLang (W-blocks,
// design §4; the reference example for the placement_rule{} construct)
//
//   import "blocks"
//
// Minestom ships ZERO default placement rules: a freshly placed stair does
// not orient, a fence does not connect, a log keeps its default axis. Every
// orientation/connection rule is the server's to author. This addon rebuilds
// the common vanilla families PURELY in SwoftLang using placement_rule{} —
// so importing it gives you vanilla placement behavior, and reading it shows
// exactly how the API is meant to be used.
//
// Families covered (design §4):
//   * stairs  — facing from the player's look (yaw), half from the clicked
//               face + cursor, shape (straight/inner/outer) from neighbours
//   * slabs   — top/bottom from face + cursor, single -> double on restack
//   * logs    — axis (x/y/z) from the clicked face (pillars/bamboo too)
//   * fences  — north/south/east/west connections to neighbours (+ panes/bars)
//   * walls   — none/low connections + the centre 'up' post
//   * doors   — facing + hinge + the paired upper/lower halves
//   * waterlogging — placing into a water source keeps the water
//
// The placement callback receives (location, face, cursor, against, player):
//   location  the cell being placed into (a Location)
//   face      the clicked block face: "top"/"bottom"/"north"/… (a String)
//   cursor    the sub-block hit point, each component in 0..1 (a Vec)
//   against   the block the click landed on (a Block)
//   player    the PLACING PLAYER'S POSITION — a Location carrying .yaw/.pitch
//             (Minestom's placement state exposes no Player, only a position);
//             this is the orientation-from-look source for stairs and doors.
// on_place returns the oriented Block to set. on_update(location, block,
// neighbours) recomputes connections when a neighbour changes: 'neighbours'
// is a Map<String,Block> keyed by the six face names.
//
// Fidelity note: block collision/solidity (Minestom's isSolid) is not exposed
// to scripts, so "does this neighbour connect?" is approximated by block id
// (see bl_no_connect). It is faithful for the common cases; a production rule
// that needs exact solidity would extend the Block value with an is_solid
// accessor. Everything else mirrors vanilla.
// =========================================================================

// ------------------------------------------------------------------ geometry

// The horizontal direction the player is looking, from Minecraft yaw:
// 0 = south, 90 = west, 180 = north, 270 = east. Stairs/doors face this way.
export function facing_from_yaw(yaw: Double) {
    set idx to floor(yaw / 90.0 + 0.5) % 4
    set idx to (idx + 4) % 4
    set dirs to ["south", "west", "north", "east"]
    return dirs.get(idx) otherwise "north"
}

// The pillar axis implied by the clicked face: top/bottom -> y, n/s -> z,
// e/w -> x. Used by logs, bamboo, and other pillar blocks.
export function axis_from_face(face: String) {
    if (face is "up") or (face is "top") return "y"
    if (face is "down") or (face is "bottom") return "y"
    if (face is "north") or (face is "south") return "z"
    return "x"
}

// Opposite of a horizontal facing.
function bl_opposite(dir: String) {
    if dir is "north" return "south"
    if dir is "south" return "north"
    if dir is "east" return "west"
    if dir is "west" return "east"
    return dir
}

// Counter-clockwise (looking down): north -> west -> south -> east -> north.
function bl_ccw(dir: String) {
    if dir is "north" return "west"
    if dir is "west" return "south"
    if dir is "south" return "east"
    if dir is "east" return "north"
    return dir
}

// The horizontal axis a facing lies on ("z" for n/s, "x" for e/w).
function bl_axis_of(dir: String) {
    if (dir is "north") or (dir is "south") return "z"
    return "x"
}

// The Location one block away from 'loc' in a face direction.
function bl_relative(loc: Location, dir: String) {
    if dir is "north" return location(loc.x, loc.y, loc.z - 1.0)
    if dir is "south" return location(loc.x, loc.y, loc.z + 1.0)
    if dir is "east" return location(loc.x + 1.0, loc.y, loc.z)
    if dir is "west" return location(loc.x - 1.0, loc.y, loc.z)
    if dir is "up" return location(loc.x, loc.y + 1.0, loc.z)
    if dir is "down" return location(loc.x, loc.y - 1.0, loc.z)
    return loc
}

// The six face-adjacent world blocks as a Map<String,Block> — the same shape
// on_update receives, so on_place can reuse the connection helpers by reading
// the world itself (on_place is not handed a neighbour map).
function bl_neighbours(loc: Location) {
    return {
        "north": block_at(bl_relative(loc, "north")),
        "south": block_at(bl_relative(loc, "south")),
        "east": block_at(bl_relative(loc, "east")),
        "west": block_at(bl_relative(loc, "west")),
        "up": block_at(bl_relative(loc, "up")),
        "down": block_at(bl_relative(loc, "down"))
    }
}

// -------------------------------------------------------------- shared rules

// "top" or "bottom" for the upper/lower placement of stairs (half) and slabs
// (type): clicking the underside (face "bottom") or the top part of a side
// face puts the block up top; otherwise it sits on the bottom.
function bl_top_or_bottom(face: String, cursor: Vec) {
    if face is "bottom" return "top"
    if (face is not "top") and (cursor.y > 0.5) return "top"
    return "bottom"
}

// True if placing into a water source — the block should then waterlog. The
// world still holds the replaced block while the placement callback runs, so
// block_at(location) sees the water we are about to occupy.
function bl_waterlogged_here(loc: Location) {
    set here to block_at(loc)
    if here.id is "minecraft:water" return "true"
    return "false"
}

// -------------------------------------------------------------------- stairs

function bl_is_stairs(b: Block) {
    return b.id.ends_with("_stairs")
}

// Vanilla stair shape from the stairs in front of / behind this one. A
// perpendicular neighbour turns the corner: outer when it faces away, inner
// when it faces in; left/right from whether that facing is our ccw side.
function bl_stairs_shape(cur: Block, neighbours: Map<String, Block>) {
    set f to cur.property("facing") otherwise "north"
    set h to cur.property("half") otherwise "bottom"

    set front to neighbours.get(f) otherwise block("air")
    if bl_is_stairs(front) {
        set fh to front.property("half") otherwise ""
        set ff to front.property("facing") otherwise ""
        if (fh is h) and (bl_axis_of(ff) is not bl_axis_of(f)) {
            if ff is bl_ccw(f) return "outer_left"
            return "outer_right"
        }
    }

    set back to neighbours.get(bl_opposite(f)) otherwise block("air")
    if bl_is_stairs(back) {
        set bh to back.property("half") otherwise ""
        set bf to back.property("facing") otherwise ""
        if (bh is h) and (bl_axis_of(bf) is not bl_axis_of(f)) {
            if bf is bl_ccw(f) return "inner_left"
            return "inner_right"
        }
    }

    return "straight"
}

function bl_place_stairs(id: String, loc: Location, face: String, cursor: Vec, player: Location) {
    set base to block(id)
        .with("facing", facing_from_yaw(player.yaw))
        .with("half", bl_top_or_bottom(face, cursor))
        .with("waterlogged", bl_waterlogged_here(loc))
    return base.with("shape", bl_stairs_shape(base, bl_neighbours(loc)))
}

function bl_update_stairs(cur: Block, neighbours: Map<String, Block>) {
    return cur.with("shape", bl_stairs_shape(cur, neighbours))
}

// --------------------------------------------------------------------- slabs

function bl_place_slab(id: String, loc: Location, face: String, cursor: Vec) {
    set placed to block(id)
    // clicking an existing matching slab stacks it into a double slab
    set here to block_at(loc)
    if here.id is placed.id {
        set t to here.property("type") otherwise "bottom"
        if t is not "double" return placed.with("type", "double")
    }
    return placed
        .with("type", bl_top_or_bottom(face, cursor))
        .with("waterlogged", bl_waterlogged_here(loc))
}

// ---------------------------------------------------------------------- logs

function bl_place_log(id: String, face: String) {
    return block(id).with("axis", axis_from_face(face))
}

// ------------------------------------------------------ fences / panes / bars

// Blocks a fence/pane/bar/wall does NOT attach to. Air and fluids never
// connect; a few common non-solid decorations are excluded too. Everything
// else counts as a connection (an id-based stand-in for real solidity — see
// the header note).
function bl_no_connect(id: String) {
    if id is "minecraft:air" return true
    if id is "minecraft:cave_air" return true
    if id is "minecraft:void_air" return true
    if id is "minecraft:water" return true
    if id is "minecraft:lava" return true
    if id is "minecraft:short_grass" return true
    if id is "minecraft:tall_grass" return true
    if id is "minecraft:fern" return true
    if id is "minecraft:torch" return true
    if id.ends_with("_sapling") return true
    return false
}

// "true"/"false" for one side of a fence/pane/bar.
function bl_fence_side(neighbours: Map<String, Block>, dir: String) {
    set n to neighbours.get(dir) otherwise block("air")
    if bl_no_connect(n.id) return "false"
    return "true"
}

// Set the four horizontal connection flags on a fence/pane/bar, preserving
// everything else (including waterlogged) already on 'base'.
function bl_apply_fence(neighbours: Map<String, Block>, base: Block) {
    return base
        .with("north", bl_fence_side(neighbours, "north"))
        .with("south", bl_fence_side(neighbours, "south"))
        .with("east", bl_fence_side(neighbours, "east"))
        .with("west", bl_fence_side(neighbours, "west"))
}

function bl_place_fence(id: String, loc: Location) {
    set base to block(id).with("waterlogged", bl_waterlogged_here(loc))
    return bl_apply_fence(bl_neighbours(loc), base)
}

// --------------------------------------------------------------------- walls

// "low"/"none" for one wall side (walls use none/low/tall; tall is reserved
// for cases needing real height data, so this rule produces none/low).
function bl_wall_side(neighbours: Map<String, Block>, dir: String) {
    set n to neighbours.get(dir) otherwise block("air")
    if bl_no_connect(n.id) return "none"
    return "low"
}

function bl_apply_wall(neighbours: Map<String, Block>, base: Block) {
    set nn to bl_wall_side(neighbours, "north")
    set ss to bl_wall_side(neighbours, "south")
    set ee to bl_wall_side(neighbours, "east")
    set ww to bl_wall_side(neighbours, "west")
    set b to base
        .with("north", nn).with("south", ss).with("east", ee).with("west", ww)

    // the centre post disappears only for a clean straight run with nothing
    // stacked on top; otherwise vanilla keeps the post ('up' = true)
    set above to neighbours.get("up") otherwise block("air")
    set straight_ns to (nn is not "none") and (ss is not "none") and (ee is "none") and (ww is "none")
    set straight_ew to (ee is not "none") and (ww is not "none") and (nn is "none") and (ss is "none")
    set up_post to "true"
    if (straight_ns or straight_ew) and bl_no_connect(above.id) set up_post to "false"
    return b.with("up", up_post)
}

function bl_place_wall(id: String, loc: Location) {
    set base to block(id).with("waterlogged", bl_waterlogged_here(loc))
    return bl_apply_wall(bl_neighbours(loc), base)
}

// --------------------------------------------------------------------- doors

// Hinge side from where on the face the click landed, relative to the door's
// facing. (Vanilla also inspects adjacent doors and the block above; this
// approximates with the click side, which the placement state does expose.)
function bl_hinge_pick(t: Double) {
    if t < 0.5 return "left"
    return "right"
}

function bl_door_hinge(facing: String, cursor: Vec) {
    if facing is "north" return bl_hinge_pick(cursor.x)
    if facing is "south" return bl_hinge_pick(1.0 - cursor.x)
    if facing is "east" return bl_hinge_pick(cursor.z)
    return bl_hinge_pick(1.0 - cursor.z)
}

// A door is two blocks. The placement rule returns the LOWER half and sets the
// UPPER half itself, one cell up. set block during placement is a programmatic
// write (it does not re-run this rule), so there is no recursion; if the cell
// above is obstructed the write is a harmless no-op replace.
function bl_place_door(id: String, loc: Location, cursor: Vec, player: Location) {
    set f to facing_from_yaw(player.yaw)
    set hinge to bl_door_hinge(f, cursor)
    set lower to block(id).with("facing", f).with("hinge", hinge).with("half", "lower")
    set upper to block(id).with("facing", f).with("hinge", hinge).with("half", "upper")
    set block at location(loc.x, loc.y + 1.0, loc.z) to upper
    return lower
}

// =========================================================================
// Placement-rule registrations. Each declaration is an EFFECT: importing this
// module registers the rule with the engine (no export needed). The bodies
// are one-liners that delegate to the shared helpers above, so adding another
// wood/stone variant is a single copy of the block below. A representative set
// of each family is wired up here; extend it with your own block ids.
// =========================================================================

// ---- stairs ----
placement_rule for "oak_stairs" {
    on_place -> Block {
        return bl_place_stairs("oak_stairs", location, face, cursor, player)
    }
    on_update -> Block {
        return bl_update_stairs(block, neighbors)
    }
    self_replaceable: false
}

placement_rule for "stone_stairs" {
    on_place -> Block {
        return bl_place_stairs("stone_stairs", location, face, cursor, player)
    }
    on_update -> Block {
        return bl_update_stairs(block, neighbors)
    }
    self_replaceable: false
}

placement_rule for "cobblestone_stairs" {
    on_place -> Block {
        return bl_place_stairs("cobblestone_stairs", location, face, cursor, player)
    }
    on_update -> Block {
        return bl_update_stairs(block, neighbors)
    }
    self_replaceable: false
}

// ---- slabs (self_replaceable so clicking one stacks it to a double) ----
placement_rule for "oak_slab" {
    on_place -> Block {
        return bl_place_slab("oak_slab", location, face, cursor)
    }
    self_replaceable: true
}

placement_rule for "stone_slab" {
    on_place -> Block {
        return bl_place_slab("stone_slab", location, face, cursor)
    }
    self_replaceable: true
}

placement_rule for "cobblestone_slab" {
    on_place -> Block {
        return bl_place_slab("cobblestone_slab", location, face, cursor)
    }
    self_replaceable: true
}

// ---- logs / pillars ----
placement_rule for "oak_log" {
    on_place -> Block {
        return bl_place_log("oak_log", face)
    }
    self_replaceable: false
}

placement_rule for "birch_log" {
    on_place -> Block {
        return bl_place_log("birch_log", face)
    }
    self_replaceable: false
}

placement_rule for "bamboo_block" {
    on_place -> Block {
        return bl_place_log("bamboo_block", face)
    }
    self_replaceable: false
}

// ---- fences / glass panes / iron bars ----
placement_rule for "oak_fence" {
    on_place -> Block {
        return bl_place_fence("oak_fence", location)
    }
    on_update -> Block {
        return bl_apply_fence(neighbors, block)
    }
    self_replaceable: false
}

placement_rule for "spruce_fence" {
    on_place -> Block {
        return bl_place_fence("spruce_fence", location)
    }
    on_update -> Block {
        return bl_apply_fence(neighbors, block)
    }
    self_replaceable: false
}

placement_rule for "glass_pane" {
    on_place -> Block {
        return bl_place_fence("glass_pane", location)
    }
    on_update -> Block {
        return bl_apply_fence(neighbors, block)
    }
    self_replaceable: false
}

placement_rule for "iron_bars" {
    on_place -> Block {
        return bl_place_fence("iron_bars", location)
    }
    on_update -> Block {
        return bl_apply_fence(neighbors, block)
    }
    self_replaceable: false
}

// ---- walls ----
placement_rule for "cobblestone_wall" {
    on_place -> Block {
        return bl_place_wall("cobblestone_wall", location)
    }
    on_update -> Block {
        return bl_apply_wall(neighbors, block)
    }
    self_replaceable: false
}

// ---- doors (facing + hinge + paired upper/lower) ----
placement_rule for "oak_door" {
    on_place -> Block {
        return bl_place_door("oak_door", location, cursor, player)
    }
    self_replaceable: false
}

placement_rule for "iron_door" {
    on_place -> Block {
        return bl_place_door("iron_door", location, cursor, player)
    }
    self_replaceable: false
}
