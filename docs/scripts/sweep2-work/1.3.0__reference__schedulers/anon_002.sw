command "meteor" {
    execute {
        set warning to schedule after 3 seconds {
            broadcast "<red>Incoming!"
        }

        set shake to schedule every 10 ticks {
            play sound "minecraft:entity.generic.explode" to all volume 0.2 pitch 0.5
        }

        set finale to schedule after 5 seconds every 1 seconds {
            spawn particle "EXPLOSION_EMITTER" at location(0.5, 80.0, 0.5) count 1
        }

        cancel schedule warning
        cancel schedule shake
        cancel schedule finale
    }
}
