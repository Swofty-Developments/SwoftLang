// a mob type used where a reusable goal type is required
mob Blob {
    type: "SLIME"
}

mob Critter {
    type: "RABBIT"
    ai {
        target closest Player within 6
        goals: [ Blob ]
    }
}
