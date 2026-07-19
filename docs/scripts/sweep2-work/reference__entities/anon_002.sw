command "snippetwrap" {
    execute {
        spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
        set stand.custom_name to "<gold>Landmark"
        set stand.name_visible to true
        set stand.glowing to true
        set stand.gravity to false
        set stand.invisible to false
        set stand.silent to true
    }
}
