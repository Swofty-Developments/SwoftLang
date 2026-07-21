#!/usr/bin/env node
// Generates data/packets.json for the SwoftLang VS Code extension.
//
// Source of truth: compiler/data/packets.json (produced by
// compiler/data/GenMinestomCatalogs.java from the pinned Minestom jar). That
// file is keyed by fully-qualified record class and carries every record
// component. The LSP only needs the SIMPLE class name (that's what
// `Packet { on "..." }` uses), the direction (client = inbound, listened to;
// server = outbound), and each field's SwoftLang-visible name + type.
//
// `packet.<field>` in the language resolves on the snake_case `name` (see
// registry.ml `packet_fields`), so we key fields on `name` and map the catalog
// `ty` spelling to the friendly SwoftLang type shown in completion/hover.
//
// Re-run with: node scripts/gen-packets.js
'use strict';
const fs = require('fs');
const path = require('path');

const CATALOG = path.join(
  __dirname, '..', '..', '..', 'compiler', 'data', 'packets.json',
);
const OUT = path.join(__dirname, '..', 'data', 'packets.json');

// catalog "ty" spelling -> friendly SwoftLang type name (matches the ty algebra
// in registry.ml ty_of_catalog_string). TAny falls back to the java type below.
const TY_TO_NAME = {
  TString: 'String', TInteger: 'Integer', TDouble: 'Double', TBoolean: 'Boolean',
  TItem: 'Item', TLocation: 'Location', TVec: 'Vec', TPlayer: 'Player',
  TEntity: 'Entity', TMob: 'Mob', TBlock: 'Block', TWorld: 'World',
};

// last path segment of a java type (strip package + nested `$`), e.g.
// `net...ClientPlayerActionPacket$Status` -> `Status`, `byte[]` -> `byte[]`.
function javaSimple(jt) {
  if (!jt) return 'Any';
  return jt.replace(/^.*[.$]/, '');
}

function build() {
  const catalog = JSON.parse(fs.readFileSync(CATALOG, 'utf8'));
  const packets = {};
  let clientCount = 0;
  let serverCount = 0;
  for (const [fq, v] of Object.entries(catalog)) {
    if (fq === '_meta' || !v || !Array.isArray(v.fields)) continue;
    const simple = v.simple_name || javaSimple(fq);
    const direction = v.direction || 'server';
    if (direction === 'client') clientCount++;
    else serverCount++;
    const fields = v.fields.map((f) => ({
      name: f.name,
      type: TY_TO_NAME[f.ty] || javaSimple(f.javaType),
      javaType: f.javaType,
    }));
    packets[simple] = { fq, direction, fields };
  }
  const out = {
    generatedBy: 'scripts/gen-packets.js',
    note: 'Compact packet catalog for the LSP. Source: compiler/data/packets.json. '
      + 'direction "client" = inbound (listened to by Packet { on "..." }); '
      + '"server" = outbound. Fields keyed on the snake_case name packet.<field> uses.',
    _meta: catalog._meta,
    clientCount,
    serverCount,
    packets,
  };
  fs.writeFileSync(OUT, JSON.stringify(out, null, 2) + '\n');
  console.error(
    `wrote ${OUT}: ${Object.keys(packets).length} packets `
    + `(${clientCount} client/inbound, ${serverCount} server/outbound)`,
  );
}

build();
