command "snippetwrap" {
    execute {
        set v to velocity(0.5, 1.5, -0.5)
        set v.y to 3.0
        set total to v.x + v.y + v.z
    }
}
