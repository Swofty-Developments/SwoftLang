command "vecs" {
    execute {
        set v to vec(3.0, 4.0, 0.0)
        send "length ${v.length}" to sender           // 5.0
        send "unit x ${v.normalized.x}" to sender      // 0.6
    }
}
