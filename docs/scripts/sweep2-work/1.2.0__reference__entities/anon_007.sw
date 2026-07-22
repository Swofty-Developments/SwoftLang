command "snippetwrap" {
    execute {
        launch projectile "SNOWBALL" from sender with speed 2.5 as ball
        set ball.glowing to true
        send "lobbed a ${ball.type}" to sender

        launch projectile "ARROW" from sender with velocity velocity(0.0, 1.0, 0.0)
        launch projectile "FIREBALL" from sender
    }
}
