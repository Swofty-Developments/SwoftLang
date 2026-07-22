struct Session {
    id: String
    world: optional<World> = none
}

persistent sess: Session = Session { id: "" }
