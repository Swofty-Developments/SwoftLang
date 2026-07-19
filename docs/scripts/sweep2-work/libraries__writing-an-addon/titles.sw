// =========================================================================
// titles.sw — big-screen text helpers
//
//   import "titles"
//
//   announce(player, "<bold>Boss incoming")
//   announce_all("Sudden death!")
//   set_title_style(function(text: String) return "<red>${text}")
//   spawn countdown(player, 3, function(p: Player) send "go!" to p)
// =========================================================================

// module-private state: the formatting lambda every announcement goes through
var title_style = function(text: String) return "<gold><bold>${text}"

// private: one place that applies the current style
function styled(text: String) {
    return title_style(text)
}

// Show a styled title to one player.
export function announce(target: Player, text: String) {
    title styled(text) to target fade in 5 ticks stay 40 ticks fade out 10 ticks
}

// Show a styled title to everyone online.
export function announce_all(text: String) {
    loop all players as p {
        announce(p, text)
    }
}

// Swap the style used by every future announcement.
export function set_title_style(style) {
    set title_style to style
}

// 3.. 2.. 1.. GO — then hand control back through the callback.
export async function countdown(target: Player, from: Integer, done) {
    loop from times as i {
        title "<yellow>${from - i + 1}" to target stay 15 ticks
        wait 1 seconds
    }
    title "<green>GO!" to target stay 20 ticks
    done(target)
}
