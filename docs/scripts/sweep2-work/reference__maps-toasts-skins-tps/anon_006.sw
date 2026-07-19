command "dramatic" {
    execute {
        play sound "minecraft:entity.ender_dragon.growl" to all volume 0.8 pitch 0.7
        play sound "minecraft:block.bell.use" to sender at sender.location
        stop sound "minecraft:entity.ender_dragon.growl" for all
        stop sound for sender
    }
}
