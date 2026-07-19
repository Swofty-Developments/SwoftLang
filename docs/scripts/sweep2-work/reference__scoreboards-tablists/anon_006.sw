command "bn" {
    execute {
        belowname "<red>hearts" for sender                  // label under the name tag
        set belowname score to sender.health for sender     // the number next to it
        clear belowname for sender
    }
}
