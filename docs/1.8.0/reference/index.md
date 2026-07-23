# Reference

<p class="sw-lead">Exact syntax, exact signatures, exact compiler output. Every snippet here is
validated against <code>swoftc</code> — if it's shown compiling, it compiles; if it's
shown failing, that's real compiler output, byte for byte.</p>

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">Language</h2><span class="sw-hub-sec-note">syntax, types, tooling</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/reference/syntax-cheatsheet"><span class="sw-hub-body"><span class="sw-hub-title">Syntax Cheatsheet</span><span class="sw-hub-desc">Every construct at a glance — the one-page version of the whole language.</span></span></a>
<a class="sw-hub-card" href="/reference/maps"><span class="sw-hub-body"><span class="sw-hub-title">Maps</span><span class="sw-hub-desc">The <code>map&lt;V&gt;</code> type — literals, <code>map_*</code> builtins, index sugar, iteration, persistent scalar maps.</span></span></a>
<a class="sw-hub-card" href="/reference/collections"><span class="sw-hub-body"><span class="sw-hub-title">Collections &amp; Strings</span><span class="sw-hub-desc">The <code>receiver.method(args)</code> forms — list, map, and String methods, pure vs mutating, and the zero-arg accessors.</span></span></a>
<a class="sw-hub-card" href="/reference/builtins"><span class="sw-hub-body"><span class="sw-hub-title">Builtins</span><span class="sw-hub-desc">Every builtin function with checked signatures.</span></span></a>
<a class="sw-hub-card" href="/reference/events"><span class="sw-hub-body"><span class="sw-hub-title">Receivers & Events</span><span class="sw-hub-desc">The receiver catalog — every receiver, its methods, fan-out, and the override rule.</span></span></a>
<a class="sw-hub-card" href="/reference/cli"><span class="sw-hub-body"><span class="sw-hub-title">CLI — swoftc</span><span class="sw-hub-desc">Compile and check, sidecars, exit codes, how the runtime finds the binary.</span></span></a>
</div>
</div>

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">Content</h2><span class="sw-hub-sec-note">things you place in the world</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/reference/items"><span class="sw-hub-body"><span class="sw-hub-title">Custom Items</span><span class="sw-hub-desc"><code>item</code> declarations — material or skull, rarity, WYSIWYG lore, the nested NBT tag API, <code>on_click</code>.</span></span></a>
<a class="sw-hub-card" href="/reference/mobs"><span class="sw-hub-body"><span class="sw-hub-title">Custom Mobs</span><span class="sw-hub-desc"><code>mob</code> declarations — AI, drops, handlers, the <code>Mob</code> value.</span></span></a>
<a class="sw-hub-card" href="/reference/entities"><span class="sw-hub-body"><span class="sw-hub-title">Entities</span><span class="sw-hub-desc">The shared <code>Entity</code> table, spawn/mount/remove, velocity vectors, launching projectiles.</span></span></a>
<a class="sw-hub-card" href="/reference/combat"><span class="sw-hub-body"><span class="sw-hub-title">Combat &amp; PvP</span><span class="sw-hub-desc">Build vanilla combat in-language — the enriched <code>EntityDamage</code> event, attributes as entity properties, the <code>damage</code>/<code>knock</code>/<code>apply</code>/<code>shoot</code> verbs, and per-entity <code>.tags</code>.</span></span></a>
<a class="sw-hub-card" href="/reference/fishing"><span class="sw-hub-body"><span class="sw-hub-title">Fishing</span><span class="sw-hub-desc"><code>fishing_loot</code> tables, the bite window, the four fishing events.</span></span></a>
<a class="sw-hub-card" href="/reference/dispensers"><span class="sw-hub-body"><span class="sw-hub-title">Dispensers &amp; Droppers</span><span class="sw-hub-desc">Block-entity inventories, the activation model, <code>dispense from</code>, <code>BlockDispense</code>.</span></span></a>
<a class="sw-hub-card" href="/reference/offline-players"><span class="sw-hub-body"><span class="sw-hub-title">Offline Players</span><span class="sw-hub-desc">The <code>OfflinePlayer</code> type, the seen-store, the <code>.player</code> bridge.</span></span></a>
<a class="sw-hub-card" href="/reference/gui"><span class="sw-hub-body"><span class="sw-hub-title">GUIs</span><span class="sw-hub-desc">Declarative inventories — slots, state, pagination, editable regions.</span></span></a>
<a class="sw-hub-card" href="/reference/scoreboards-tablists"><span class="sw-hub-body"><span class="sw-hub-title">Scoreboards &amp; Tablists</span><span class="sw-hub-desc">Sidebars, player-list columns, bossbars, titles, actionbars.</span></span></a>
<a class="sw-hub-card" href="/reference/nametags"><span class="sw-hub-body"><span class="sw-hub-title">Nametags</span><span class="sw-hub-desc">Per-viewer name, prefix, suffix, color.</span></span></a>
<a class="sw-hub-card" href="/reference/displays"><span class="sw-hub-body"><span class="sw-hub-title">Displays</span><span class="sw-hub-desc">Text, item, and block display entities.</span></span></a>
<a class="sw-hub-card" href="/reference/holograms"><span class="sw-hub-body"><span class="sw-hub-title">Holograms</span><span class="sw-hub-desc">The <code>hologram</code> block — a billboarded line stack, per-viewer text, show/set/move statements.</span></span></a>
<a class="sw-hub-card" href="/reference/npcs"><span class="sw-hub-body"><span class="sw-hub-title">NPCs</span><span class="sw-hub-desc">The <code>npc</code> block — skinned, head-tracking player NPCs with inline click handlers.</span></span></a>
</div>
</div>

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">Platform</h2><span class="sw-hub-sec-note">the server around your scripts</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/reference/server-config"><span class="sw-hub-body"><span class="sw-hub-title">Server Config</span><span class="sw-hub-desc">The <code>server</code> block — auth, http, permissions, MOTD, storage.</span></span></a>
<a class="sw-hub-card" href="/reference/worlds"><span class="sw-hub-body"><span class="sw-hub-title">Worlds</span><span class="sw-hub-desc">Anvil/polar/storage loaders, world lifecycle, weather and time.</span></span></a>
<a class="sw-hub-card" href="/reference/blocks"><span class="sw-hub-body"><span class="sw-hub-title">Blocks</span><span class="sw-hub-desc">The <code>block(...)</code> state value, NBT tags, <code>block_handler</code> and <code>placement_rule</code> — plus the ready-made vanilla-placement addon.</span></span></a>
<a class="sw-hub-card" href="/reference/http-api"><span class="sw-hub-body"><span class="sw-hub-title">HTTP API</span><span class="sw-hub-desc"><code>api</code> routes, <code>request</code>, <code>reply</code>.</span></span></a>
<a class="sw-hub-card" href="/reference/songs"><span class="sw-hub-body"><span class="sw-hub-title">Songs</span><span class="sw-hub-desc">NBS playback and metadata.</span></span></a>
<a class="sw-hub-card" href="/reference/maps-toasts-skins-tps"><span class="sw-hub-body"><span class="sw-hub-title">Maps, Toasts, Skins &amp; TPS</span><span class="sw-hub-desc">Map canvases, toasts, skin control, TPS introspection, sounds, particles.</span></span></a>
<a class="sw-hub-card" href="/reference/schedulers"><span class="sw-hub-body"><span class="sw-hub-title">Schedulers</span><span class="sw-hub-desc"><code>every</code> blocks and the <code>schedule</code> expression.</span></span></a>
<a class="sw-hub-card" href="/reference/packets"><span class="sw-hub-body"><span class="sw-hub-title">Raw Packets</span><span class="sw-hub-desc">The NMS escape hatch — sharp edges included.</span></span></a>
</div>
</div>

<div class="sw-hub-sec">
<div class="sw-hub-sec-head"><h2 class="sw-hub-sec-title">Internals</h2><span class="sw-hub-sec-note">tooling and debugging only</span></div>
<div class="sw-hub">
<a class="sw-hub-card" href="/reference/json-ast"><span class="sw-hub-body"><span class="sw-hub-title">JSON AST</span><span class="sw-hub-desc">The compiler-to-runtime wire format.</span></span></a>
</div>
</div>

Looking for the stdlib addons — holograms, NPCs, music, abilities? They live in
[Libraries](/1.8.0/libraries/), alongside a tutorial on writing your own.
