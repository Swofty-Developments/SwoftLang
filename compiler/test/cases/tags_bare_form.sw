// Legacy bare form: 'tags {}' — still accepted. Must emit byte-identical JSON to
// tags_colon_form.sw (canonical colon form). Proves the colon is surface-only.
item ColonItem {
    material: "STICK"
    tags {}
}
