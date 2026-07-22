struct Session {
    id: String
    world: Optional<World> = none
}

persistent sess: Session = Session { id: "" }
