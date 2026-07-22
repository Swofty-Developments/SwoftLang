// coins.sw — a tiny economy module
var total_minted = 0

function mint(amount: Integer) {
    set total_minted to total_minted + amount
    return total_minted
}

export function give_coins(p: Player, amount: Integer) {
    mint(amount)
    send "<gold>+${amount} coins" to p
}

export function coins_minted() {
    return total_minted
}
