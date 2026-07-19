command "snippetwrap" {
    execute {
        spawn entity "minecraft:pig" at location(4.5, 65.0, 4.5) as mount_pig
        spawn entity "ARMOR_STAND" at location(4.5, 65.0, 4.5) as stand
        mount stand on mount_pig
        loop mount_pig.passengers as rider {
            send "riding: ${rider.type}" to all
        }
        if stand.vehicle exists {
            send "the statue found a ride" to all
        }
        dismount stand
        remove entity stand
        remove entity mount_pig
    }
}
