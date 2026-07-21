// 'call original method' is only valid inside a custom declaration method that
// overrides a base receiver method; a base receiver method overrides nothing.
Mob {
    on_click {
        call original method
    }
}
