struct Party {
    boss: Mob
    size: Integer = 1
}

persistent parties: map<String, Party> = new_map()
