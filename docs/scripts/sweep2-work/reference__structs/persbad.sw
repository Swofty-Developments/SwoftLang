struct Party {
    boss: Mob
    size: Integer = 1
}

persistent parties: Map<String, Party> = new_map()
