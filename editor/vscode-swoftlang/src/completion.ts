/*
 * Context-aware completion for SwoftLang.
 *
 * Instead of dumping all ~1100 symbols on every keystroke, we inspect the text
 * on the line before the cursor (and the enclosing block) and return only the
 * bucket that can legally appear there. This module is deliberately free of any
 * LSP connection state so it can be driven directly from a headless test.
 *
 *   - after `.`                       -> property names of the receiver's type
 *   - after `:` / inside `<…>` / `is`  -> types only
 *   - `<key>:` config value            -> that key's enum/bareword values
 *   - inside a "…" string              -> MiniMessage tags after `<`, else nothing
 *   - statement start, top level        -> declaration keywords (snippets)
 *   - statement start inside `attributes {` -> attribute keys
 *   - statement start inside a decl body -> config keys + handlers + namespaces
 *   - statement start inside a block     -> statement keywords + builtins + consts
 *   - any other expression position      -> locals + builtins + consts + operators
 *
 * The full breadth (every keyword / builtin / type / enum group / handler /
 * namespace / per-owner property) is driven by the bundled symbol dump, so this
 * file never hard-codes symbol lists that can drift from the compiler.
 */
import {
  CompletionItem,
  CompletionItemKind,
  InsertTextFormat,
  MarkupKind,
} from 'vscode-languageserver/node';

export interface Sym {
  name: string;
  kind: string;
  signature?: string;
  signatures?: string[];
  doc?: string;
  owner?: string;
  type?: string;
  writable?: boolean;
}
export interface SymData {
  symbols: Sym[];
  enums: Record<string, string[]>;
  namespaces?: string[];
  handlers?: string[];
}

// --- packet catalog (bundled data/packets.json, see scripts/gen-packets.js) ---
export interface PacketField {
  name: string; // snake_case — the spelling `packet.<field>` uses
  type: string; // friendly SwoftLang type, e.g. 'Integer', 'Location', 'Status'
  javaType?: string;
}
export interface PacketInfo {
  fq: string;
  direction: string; // 'client' = inbound (listened to); 'server' = outbound
  fields: PacketField[];
}
export interface PacketData {
  packets: Record<string, PacketInfo>; // keyed by SIMPLE class name
}

// What the analyzer can work out about the cursor's surroundings, used to infer
// the type of a `.`-receiver so property completion is owner-precise, and the
// enclosing block so config-key/handler/attribute completion is context-precise.
export interface ScriptContext {
  event?: string; // enclosing `event <Name> { }` handler name, e.g. 'PlayerJoin'
  argTypes?: Record<string, string>; // command `arguments { name: Type }`
  varTypes?: Record<string, string>; // locals with an inferable type
  block?: string; // innermost enclosing block opener keyword, e.g. 'item', 'attributes', 'execute'
  packetClass?: string; // enclosing `Packet { on "Class" { } }` simple class name
}

export interface CompletionEngine {
  getCompletions(
    prefix: string,
    depth: number,
    locals?: string[],
    ctx?: ScriptContext,
  ): CompletionItem[];
  resolve(item: CompletionItem): CompletionItem;
  analyze(text: string): ScriptContext;
  // Packet catalog access (undefined-safe when no packet data is bundled).
  getPacketInfo(simpleName: string): PacketInfo | undefined;
  getPacketField(simpleName: string, field: string): PacketField | undefined;
}

// Nominal subtype edges: a receiver of the subtype also exposes supertype props.
const SUPERTYPES: Record<string, string[]> = {
  Mob: ['Entity'],
  Player: ['OfflinePlayer'],
};

// Decl-body opener keyword -> the runtime type whose properties double as its
// config keys (item props: material/amount/name/lore, mob props: type/health…).
const DECL_TYPE: Record<string, string> = { item: 'Item', mob: 'Mob' };

// Decl bodies where inline `on_<event>` handler blocks and tags/attributes
// namespaces are legal at statement start.
const HANDLER_HOST = new Set([
  'item', 'mob', 'npc', 'hologram', 'block_handler', 'placement_rule', 'slot', 'gui',
]);

// Snippet templates for constructs where a fill-in-the-blanks body genuinely
// helps. Trivial keywords (halt/else/true/none/…) stay plain text.
const SNIPPETS: Record<string, string> = {
  // --- statements ---
  send: 'send "$1" to ${2:sender}',
  broadcast: 'broadcast "$1"',
  teleport: 'teleport $1 to $2',
  set: 'set ${1:name} to $2',
  give: 'give item "${1:id}" to ${2:sender} amount ${3:1}',
  title: 'title "$1" subtitle "$2" to ${3:sender}',
  actionbar: 'actionbar "$1" to ${2:sender}',
  damage: 'damage ${1:target} by ${2:1.0} as "${3:generic}"',
  reply: 'reply with "$1"',
  wait: 'wait ${1:1} ${2|tick,ticks,second,seconds|}',
  if: 'if $1 {\n\t$0\n}',
  while: 'while $1 {\n\t$0\n}',
  loop: 'loop ${1:all_players()} as ${2:p} {\n\t$0\n}',
  show: 'show ${1|scoreboard,tablist,bossbar,hologram|} "$2" to ${3:sender}',
  open: 'open gui "${1:id}" to ${2:sender}',
  close: 'close gui for ${1:sender}',
  spawn: 'spawn ${1|mob,entity,particle|} "$2" at $3',
  // --- declarations / top-level constructs ---
  command: 'command "${1:name}" {\n\texecute {\n\t\t$0\n\t}\n}',
  function: 'function ${1:name}(${2:x: Integer}) {\n\t$0\n}',
  every: 'every ${1:1} ${2|tick,ticks,second,seconds|} {\n\t$0\n}',
  schedule: 'schedule "${1:name}" every ${2:1} seconds {\n\t$0\n}',
  item: 'item "${1:id}" {\n\tmaterial: "${2:DIAMOND}"\n\tname: "$3"\n\trarity: ${4|common,uncommon,rare,epic|}\n\t$0\n}',
  mob: 'mob "${1:id}" {\n\ttype: "${2:ZOMBIE}"\n\thealth: ${3:20}\n\tai: ${4|melee,passive,none|}\n\t$0\n}',
  npc: 'npc "${1:id}" {\n\tlocation: location($2)\n\tname: "$3"\n\t$0\n}',
  hologram: 'hologram "${1:id}" {\n\tlocation: location($2)\n\tlines {\n\t\tline "$3"\n\t}\n}',
  gui: 'gui "${1:id}" {\n\trows: ${2:6}\n\ttitle: "$3"\n\t$0\n}',
  scoreboard: 'scoreboard "${1:id}" {\n\ttitle: "$2"\n\tlines {\n\t\tline "$3"\n\t}\n}',
  tablist: 'tablist "${1:id}" {\n\theader: "$2"\n\tfooter: "$3"\n}',
  bossbar: 'bossbar "${1:id}" {\n\ttext: "$2"\n\tcolor: ${3|pink,blue,red,green,yellow,purple,white|}\n\tstyle: ${4|progress,notched_6,notched_10,notched_12,notched_20|}\n}',
  block_handler: 'block_handler "${1:id}" {\n\ton_break {\n\t\t$0\n\t}\n}',
  placement_rule: 'placement_rule for "${1:block}" {\n\ton_place -> Block {\n\t\t$0\n\t}\n}',
  fishing_loot: 'fishing_loot "${1:id}" {\n\tmedium: ${2|water,lava|}\n\t$0\n}',
  api: 'api "${1:/path}" {\n\tmethod: ${2|GET,POST,PUT,DELETE,ANY|}\n\texecute {\n\t\t$0\n\t}\n}',
  server: 'server {\n\tauth: ${1|mojang,velocity,bungeecord,offline|}\n\tport: ${2:25565}\n\t$0\n}',
  storage: 'storage {\n\tbackend: "${1|sqlite,mysql,mongodb,files|}"\n}',
  persistent: 'persistent ${1:name} for Player: ${2:Integer} = $3',
  import: 'import "$1"',
  export: 'export function ${1:name}(${2}) {\n\t$0\n}',
  // --- namespaces ---
  tags: 'tags {\n\t$0\n}',
  attributes: 'attributes {\n\t$0\n}',
  tasks: 'tasks {\n\t$0\n}',
};

// Per-handler override snippets; everything else gets a bare `name { … }` block.
const HANDLER_SNIPPETS: Record<string, string> = {
  on_click: 'on_click(${1|left,right,any|}) {\n\t$0\n}',
  on_place: 'on_place -> Block {\n\t$0\n}',
  on_update: 'on_update -> Block {\n\t$0\n}',
};

function completionKind(kind: string): CompletionItemKind {
  switch (kind) {
    case 'keyword':
    case 'operator':
      return CompletionItemKind.Keyword;
    case 'declaration':
      return CompletionItemKind.Class;
    case 'type':
      return CompletionItemKind.TypeParameter;
    case 'constant':
      return CompletionItemKind.Constant;
    case 'builtin':
      return CompletionItemKind.Function;
    case 'event':
    case 'handler':
      return CompletionItemKind.Event;
    case 'namespace':
      return CompletionItemKind.Module;
    case 'property':
      return CompletionItemKind.Property;
    case 'enum':
      return CompletionItemKind.EnumMember;
    default:
      return CompletionItemKind.Text;
  }
}

// Sub-buckets for the symbols tagged plainly as `keyword`.
const STATEMENT_KEYWORDS = new Set([
  'if', 'else', 'halt', 'loop', 'while', 'return', 'wait', 'spawn', 'call', 'repeat',
  'stop', 'send', 'teleport', 'set', 'cancel', 'broadcast', 'open', 'close', 'replace',
  'show', 'hide', 'update', 'title', 'subtitle', 'actionbar', 'clear', 'line', 'blank',
  'entry', 'fill', 'give', 'dispense', 'mount', 'dismount', 'launch', 'remove', 'reset',
  'belowname', 'go', 'back', 'damage', 'knock', 'apply', 'shoot', 'move', 'play', 'draw',
  'reply', 'save', 'load',
]);
const CONNECTIVE_KEYWORDS = new Set([
  'to', 'at', 'with', 'for', 'every', 'manual', 'as', 'times', 'in', 'of', 'from', 'by',
]);
// Declaration-adjacent top-level keywords not tagged 'declaration' in the dump.
const EXTRA_TOPLEVEL = ['import', 'export'];

// A small, curated MiniMessage palette offered inside strings after `<`.
const MINIMESSAGE_TAGS = [
  'red', 'green', 'blue', 'yellow', 'aqua', 'gold', 'gray', 'white', 'black',
  'dark_red', 'dark_green', 'dark_blue', 'dark_aqua', 'dark_gray', 'dark_purple',
  'light_purple', 'bold', 'italic', 'underlined', 'strikethrough', 'obfuscated',
  'reset', 'newline',
];

// Config property key -> exact allowed bareword values that are NOT one of the
// enum groups in the dump (auth/backend/numbers/etc). Verified against
// compiler/lib/registry.ml + parse_decl.ml/parse_ui.ml.
const LITERAL_PROPERTY_VALUES: Record<string, string[]> = {
  numbers: ['hidden', 'shown'],
  auth: ['mojang', 'velocity', 'bungeecord', 'offline'],
  backend: ['files', 'sqlite', 'mysql', 'mongodb'],
  activation: ['right_click', 'left_click'],
  filter: ['left', 'right', 'any'], // item on_click filters
  skin: ['green', 'gray', 'cyan', 'blue', 'purple', 'orange'], // tablist_skins
  lighting: ['true', 'false'],
  glint: ['true', 'false'],
  editable: ['true', 'false'],
  look_at_players: ['true', 'false'],
  update: ['manual'], // the other form `every <n> ticks|seconds` is left to the user
};

// Config property key -> the enum GROUP (in data.enums) supplying its values,
// for keys whose name differs from the group name. Keys whose name equals a
// group name (rarity/ai/weather/gamemode/pose/billboard/alignment/hand) resolve
// directly and need no entry here.
const KEY_TO_ENUM: Record<string, string> = {
  style: 'bossbar_style',
  color: 'bossbar_color',
  glow_color: 'nametag_color',
  medium: 'fishing_medium',
  method: 'api_method',
  frame: 'toast_frame',
  face: 'block_face',
  operation: 'modifier_operations',
  projectile: 'projectile_type',
};

// `<key>:` at the start of a config line, cursor in the value position.
const PROP_VALUE_RE = /^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*\w*$/;

// --- line-prefix analysis (all pure) ---

export function inUnclosedString(prefix: string): boolean {
  let inStr = false;
  for (let i = 0; i < prefix.length; i++) {
    const c = prefix[i];
    if (c === '\\') {
      i++;
      continue;
    }
    if (c === '"') inStr = !inStr;
  }
  return inStr;
}

// Capture the receiver chain a trailing `.` (with optional partial word) applies
// to: `event.player.` -> `event.player`, `args.target.x` -> `args.target.x`.
// Deliberately does not match `..` (range) or `5.` (decimal), which have no
// identifier head.
const CHAIN_RE =
  /([A-Za-z_][A-Za-z0-9_]*(?:\s*\.\s*[A-Za-z_][A-Za-z0-9_]*)*)\s*\.\s*\w*$/;

export function isTypeContext(prefix: string): boolean {
  // is / is not / is a / is an  <Type>
  if (/\bis\b(\s+not)?(\s+an?)?\s+\w*$/.test(prefix)) return true;
  // unclosed type-parameter list after a constructor:  map<…  either<Player|…
  if (/\b(?:either|optional|list|map)\s*<[^<>]*$/.test(prefix)) return true;
  // type annotation after a single colon:  name: Type   (not `::`)
  if (/(^|[^:]):\s*\w*$/.test(prefix)) return true;
  return false;
}

// Approximate brace nesting depth of the text before the cursor, skipping
// string bodies and line comments so `{`/`}` in text can't fool us.
export function braceDepth(textBefore: string): number {
  let depth = 0;
  let inStr = false;
  for (let i = 0; i < textBefore.length; i++) {
    const c = textBefore[i];
    if (inStr) {
      if (c === '\\') i++;
      else if (c === '"') inStr = false;
      continue;
    }
    if (c === '"') inStr = true;
    else if (c === '/' && textBefore[i + 1] === '/') {
      while (i < textBefore.length && textBefore[i] !== '\n') i++;
    } else if (c === '{') depth++;
    else if (c === '}') depth--;
  }
  return depth;
}

// Identifiers that must never be treated as user variables even if a regex
// happens to capture them.
const LOCAL_STOPWORDS = new Set([
  'to', 'as', 'at', 'in', 'for', 'with', 'is', 'not', 'and', 'or', 'true', 'false', 'none',
  'all', 'if', 'else', 'while', 'loop', 'set', 'times', 'function', 'persistent',
]);

// Harvest the script's own bound names from the text before the cursor, so the
// user's variables show up in expression/argument contexts. Rough lexical order
// (by appearance) with document-wide dedup — good enough for completion.
export function collectLocals(text: string): string[] {
  const order: string[] = [];
  const seen = new Set<string>();
  const add = (n: string | undefined): void => {
    if (!n || !/^[A-Za-z_]\w*$/.test(n) || LOCAL_STOPWORDS.has(n) || seen.has(n)) return;
    seen.add(n);
    order.push(n);
  };
  let m: RegExpExecArray | null;

  // `set NAME …`  and  `persistent NAME …`
  const setRe = /\bset\s+([A-Za-z_]\w*)/g;
  while ((m = setRe.exec(text))) add(m[1]);
  const persRe = /\bpersistent\s+([A-Za-z_]\w*)/g;
  while ((m = persRe.exec(text))) add(m[1]);

  // `spawn … as NAME`, `loop … as NAME`, and the map form `as K -> V`
  const asRe = /\bas\s+([A-Za-z_]\w*)(?:\s*->\s*([A-Za-z_]\w*))?/g;
  while ((m = asRe.exec(text))) {
    add(m[1]);
    add(m[2]);
  }

  // function params: `function name(a: T, b)` and lambda params: `(a, b) ->`
  const fnRe = /\bfunction\s+\w+\s*\(([^)]*)\)/g;
  const lamRe = /\(([^)]*)\)\s*->/g;
  for (const re of [fnRe, lamRe]) {
    while ((m = re.exec(text))) {
      for (const part of m[1].split(',')) {
        const id = part.trim().match(/^([A-Za-z_]\w*)/);
        if (id) add(id[1]);
      }
    }
  }

  // command `arguments { NAME: … }` — bare names usable inside execute
  const argRe = /\barguments\s*\{/g;
  while ((m = argRe.exec(text))) {
    let i = m.index + m[0].length;
    let depth = 1;
    while (i < text.length && depth > 0) {
      if (text[i] === '{') depth++;
      else if (text[i] === '}') depth--;
      i++;
    }
    const block = text.slice(m.index + m[0].length, i - 1);
    const keyRe = /(?:^|\n)\s*([A-Za-z_]\w*)\s*:/g;
    let km: RegExpExecArray | null;
    while ((km = keyRe.exec(block))) add(km[1]);
  }

  // implicit bindings available inside command/event handlers
  for (const implicit of ['event', 'sender', 'args']) if (text.includes(implicit)) add(implicit);

  return order;
}

// Walk the text before the cursor with a brace stack, tracking the opener
// keyword of each block (the first identifier on the line that carries the `{`).
// Returns the innermost still-open block keyword, e.g. 'attributes' / 'execute'
// / 'item', or undefined at top level.
export function enclosingBlock(textBefore: string): string | undefined {
  const stack: string[] = [];
  let inStr = false;
  let lineStart = 0;
  for (let i = 0; i < textBefore.length; i++) {
    const c = textBefore[i];
    if (c === '\n') lineStart = i + 1;
    if (inStr) {
      if (c === '\\') i++;
      else if (c === '"') inStr = false;
      continue;
    }
    if (c === '"') inStr = true;
    else if (c === '/' && textBefore[i + 1] === '/') {
      while (i < textBefore.length && textBefore[i] !== '\n') i++;
      if (i < textBefore.length) lineStart = i + 1;
    } else if (c === '{') {
      const seg = textBefore.slice(lineStart, i);
      const kw = /([A-Za-z_]\w*)/.exec(seg);
      stack.push(kw ? kw[1] : '');
    } else if (c === '}') stack.pop();
  }
  for (let k = stack.length - 1; k >= 0; k--) if (stack[k]) return stack[k];
  return undefined;
}

// If the cursor sits inside a `Packet { on "Class" { … } }` handler body, return
// the simple class name from the enclosing `on "…"`. Walks a brace stack (skips
// strings/comments) and returns the nearest still-open `on "…"` block that has a
// `Packet` ancestor. Pure — usable from both `analyze` and hover.
export function findEnclosingPacketClass(textBefore: string): string | undefined {
  type Frame = { kind: 'Packet' | 'on' | 'other'; cls?: string };
  const stack: Frame[] = [];
  let inStr = false;
  let lineStart = 0;
  for (let i = 0; i < textBefore.length; i++) {
    const c = textBefore[i];
    if (c === '\n') lineStart = i + 1;
    if (inStr) {
      if (c === '\\') i++;
      else if (c === '"') inStr = false;
      continue;
    }
    if (c === '"') inStr = true;
    else if (c === '/' && textBefore[i + 1] === '/') {
      while (i < textBefore.length && textBefore[i] !== '\n') i++;
      if (i < textBefore.length) lineStart = i + 1;
    } else if (c === '{') {
      const seg = textBefore.slice(lineStart, i);
      const on = /\bon\s+"([^"]+)"\s*$/.exec(seg);
      if (on) stack.push({ kind: 'on', cls: on[1] });
      else if (/(^|\s)Packet\s*$/.test(seg)) stack.push({ kind: 'Packet' });
      else stack.push({ kind: 'other' });
    } else if (c === '}') stack.pop();
  }
  for (let k = stack.length - 1; k >= 0; k--) {
    if (stack[k].kind === 'on' && stack[k].cls) {
      for (let j = k - 1; j >= 0; j--) if (stack[j].kind === 'Packet') return stack[k].cls;
    }
  }
  return undefined;
}

export function createCompletionEngine(
  data: SymData,
  packetData?: PacketData,
): CompletionEngine {
  const enums = data.enums || {};
  const namespaces = data.namespaces || ['tags', 'tasks', 'attributes'];
  const handlerNames =
    data.handlers && data.handlers.length
      ? data.handlers
      : data.symbols.filter((s) => s.kind === 'handler').map((s) => s.name);

  const buildItem = (s: Sym, idx: number): CompletionItem => {
    const item: CompletionItem = { label: s.name, kind: completionKind(s.kind), data: idx };
    if (s.kind === 'builtin' && s.signature) item.detail = s.signature;
    else if (s.kind === 'property' && s.owner) {
      item.detail = `${s.owner}.${s.name}: ${s.type}${s.writable ? '' : ' (read-only)'}`;
    } else if (s.kind === 'enum' && s.owner) item.detail = `${s.owner} value`;
    else item.detail = s.kind;
    if (s.doc) item.documentation = s.doc;
    // Snippet body only for statements/declarations/handlers/namespaces — never
    // a like-named property.
    if (
      (s.kind === 'keyword' ||
        s.kind === 'declaration' ||
        s.kind === 'namespace') &&
      SNIPPETS[s.name]
    ) {
      item.insertText = SNIPPETS[s.name];
      item.insertTextFormat = InsertTextFormat.Snippet;
    }
    return item;
  };

  const declItems: CompletionItem[] = [];
  const typeItems: CompletionItem[] = [];
  const builtinItems: CompletionItem[] = [];
  const constantItems: CompletionItem[] = [];
  const operatorItems: CompletionItem[] = [];
  const statementKwItems: CompletionItem[] = [];
  const connectiveItems: CompletionItem[] = [];
  const namespaceItems: CompletionItem[] = [];
  // Owner-precise property data for `.`-completion and chain resolution.
  const propsByOwner = new Map<string, CompletionItem[]>();
  const propReturnType = new Map<string, string>(); // `owner\0name` -> value type
  const builtinReturn = new Map<string, string>(); // builtin name -> return type

  data.symbols.forEach((s, i) => {
    const item = buildItem(s, i);
    if (s.kind === 'property' && s.owner) {
      const arr = propsByOwner.get(s.owner) || [];
      arr.push(buildItem(s, i));
      propsByOwner.set(s.owner, arr);
      if (s.type) propReturnType.set(`${s.owner} ${s.name}`, s.type);
    }
    if (s.kind === 'builtin' && s.signature) {
      const rt = s.signature.match(/:\s*([A-Za-z_]\w*)\s*$/);
      if (rt) builtinReturn.set(s.name, rt[1]);
    }
    switch (s.kind) {
      case 'declaration':
        declItems.push(item);
        break;
      // OOP receiver block heads (Player { }, Mob { }, Packet { }, ...): offer a
      // scaffold for the new event system (flat `event`/`on` forms were removed).
      case 'receiver':
        declItems.push({
          ...item,
          insertText: `${s.name} {\n\t$0\n}`,
          insertTextFormat: InsertTextFormat.Snippet,
        });
        break;
      case 'type':
        typeItems.push(item);
        break;
      case 'builtin':
        builtinItems.push(item);
        break;
      case 'constant':
        constantItems.push(item);
        break;
      case 'operator':
        operatorItems.push(item);
        break;
      case 'namespace':
        namespaceItems.push(item);
        break;
      // properties are offered owner-filtered via propsByOwner, not here.
      case 'keyword':
        if (STATEMENT_KEYWORDS.has(s.name)) statementKwItems.push(item);
        else if (CONNECTIVE_KEYWORDS.has(s.name)) connectiveItems.push(item);
        break;
      // events / enums / handlers are offered from targeted contexts, not here.
      default:
        break;
    }
  });
  for (const name of EXTRA_TOPLEVEL) {
    declItems.push({
      label: name,
      kind: CompletionItemKind.Class,
      detail: 'declaration',
      insertText: SNIPPETS[name],
      insertTextFormat: SNIPPETS[name] ? InsertTextFormat.Snippet : undefined,
      data: -1,
    });
  }

  // Inline `on_<event>` handler snippet items (from the dump's handler list).
  const handlerItems: CompletionItem[] = handlerNames.map((name) => ({
    label: name,
    kind: CompletionItemKind.Event,
    detail: 'event handler',
    insertText: HANDLER_SNIPPETS[name] || `${name} {\n\t$0\n}`,
    insertTextFormat: InsertTextFormat.Snippet,
    data: -1,
  }));

  const minimessageItems: CompletionItem[] = MINIMESSAGE_TAGS.map((t) => ({
    label: t,
    kind: CompletionItemKind.Color,
    detail: 'MiniMessage tag',
    data: -1,
  }));

  const withGroup = (items: CompletionItem[], group: string): CompletionItem[] =>
    items.map((it) => ({ ...it, sortText: `${group}${it.label}` }));

  const dedupeByLabel = (items: CompletionItem[]): CompletionItem[] => {
    const seen = new Set<string>();
    const out: CompletionItem[] = [];
    for (const it of items) {
      if (seen.has(it.label)) continue;
      seen.add(it.label);
      out.push(it);
    }
    return out;
  };

  const localItems = (names: string[]): CompletionItem[] =>
    names.map((n) => ({
      label: n,
      kind: CompletionItemKind.Variable,
      detail: 'local variable',
      data: -1,
    }));

  const enumItems = (group: string, values: string[]): CompletionItem[] =>
    values.map((v) => ({
      label: v,
      kind: CompletionItemKind.EnumMember,
      detail: `${group} value`,
      data: -1,
    }));

  // Config value set for a `<key>:` position, or undefined to fall through.
  const valuesForKey = (key: string): { group: string; values: string[] } | undefined => {
    if (LITERAL_PROPERTY_VALUES[key]) return { group: key, values: LITERAL_PROPERTY_VALUES[key] };
    const group = KEY_TO_ENUM[key] && enums[KEY_TO_ENUM[key]] ? KEY_TO_ENUM[key] : key;
    if (enums[group]) return { group, values: enums[group] };
    return undefined;
  };

  // Walk supertypes when looking up a property's value type.
  const lookupPropType = (owner: string, name: string): string | undefined => {
    for (const o of [owner, ...(SUPERTYPES[owner] || [])]) {
      const t = propReturnType.get(`${o} ${name}`);
      if (t) return t;
    }
    return undefined;
  };

  // Resolve a receiver chain (`event.player.location`) to a concrete owner type,
  // or undefined when it cannot be inferred with confidence.
  const resolveReceiverType = (chain: string, ctx: ScriptContext): string | undefined => {
    const tokens = chain.split('.').map((t) => t.trim()).filter(Boolean);
    if (tokens.length === 0) return undefined;
    const head = tokens[0];
    let type: string | undefined;
    let start = 1;
    if (head === 'event') type = ctx.event ? `event:${ctx.event}` : undefined;
    else if (head === 'sender') type = 'Player';
    else if (head === 'args') {
      if (tokens.length < 2) return undefined; // `args.` alone: no confident set
      type = ctx.argTypes?.[tokens[1]];
      start = 2;
    } else if (ctx.varTypes?.[head]) type = ctx.varTypes[head];
    else if (head === 'player') type = 'Player';
    else if (head === 'world') type = 'World';
    else return undefined; // unknown receiver -> offer nothing, not the wall
    if (!type) return undefined;
    for (let k = start; k < tokens.length; k++) {
      type = lookupPropType(type, tokens[k]);
      if (!type) return undefined;
    }
    return type;
  };

  // Every property of `type` (plus its supertypes), owner-filtered and deduped.
  const propsForType = (type: string): CompletionItem[] => {
    const items: CompletionItem[] = [];
    for (const o of [type, ...(SUPERTYPES[type] || [])]) {
      for (const it of propsByOwner.get(o) || []) items.push(it);
    }
    return dedupeByLabel(withGroup(items, '0'));
  };

  // Config keys for a decl body: the mapped runtime type's properties presented
  // as `key: ` inserts, deduped.
  const configKeysFor = (block: string): CompletionItem[] => {
    const type = DECL_TYPE[block];
    if (!type) return [];
    const out: CompletionItem[] = [];
    for (const o of [type, ...(SUPERTYPES[type] || [])]) {
      for (const it of propsByOwner.get(o) || []) {
        out.push({ ...it, insertText: `${it.label}: `, detail: 'config key' });
      }
    }
    return dedupeByLabel(out);
  };

  // --- packet catalog ---
  const packetMap: Record<string, PacketInfo> = packetData?.packets || {};
  const getPacketInfo = (name: string): PacketInfo | undefined => packetMap[name];
  const getPacketField = (name: string, field: string): PacketField | undefined =>
    packetMap[name]?.fields.find((f) => f.name === field);

  const directionDetail = (dir: string): string =>
    dir === 'client' ? 'inbound · client packet' : 'outbound · server packet';

  // Packet class-name items for `on "<CURSOR>"`. Only inbound (client) packets
  // can be listened to — the compiler (and runtime PacketSender.resolveClient)
  // reject an outbound server packet here — so outbound packets are omitted
  // entirely rather than offered and then flagged as a compile error.
  const packetClassItems: CompletionItem[] = Object.entries(packetMap)
    .filter(([, info]) => info.direction === 'client')
    .map(([simple, info]) => ({
      label: simple,
      kind: CompletionItemKind.Class,
      detail: directionDetail(info.direction),
      documentation: {
        kind: MarkupKind.Markdown,
        value:
          `\`${info.fq}\`\n\n` +
          (info.fields.length
            ? info.fields.map((f) => `- \`${f.name}\`: \`${f.type}\``).join('\n')
            : '_no fields_'),
      },
      sortText: `0${simple}`,
      data: -1,
    }));

  // Field items for `packet.<CURSOR>` inside a known handler, plus a scaffold
  // snippet that binds every field to a local so the user sees the whole shape.
  const packetFieldItems = (simpleName: string): CompletionItem[] => {
    const info = packetMap[simpleName];
    if (!info) return [];
    const items: CompletionItem[] = info.fields.map((f) => ({
      label: f.name,
      kind: CompletionItemKind.Property,
      detail: `${simpleName}.${f.name}: ${f.type} (read-only)`,
      documentation: f.javaType
        ? { kind: MarkupKind.Markdown, value: `\`${f.javaType}\`` }
        : undefined,
      sortText: `0${f.name}`,
      data: -1,
    }));
    return items;
  };

  // A single "scaffold all fields" item: inserts `set <field> to packet.<field>`
  // for every field, so the whole packet shape lands in the buffer at once.
  const packetScaffoldItem = (simpleName: string): CompletionItem | undefined => {
    const info = packetMap[simpleName];
    if (!info || info.fields.length === 0) return undefined;
    const body = info.fields
      .map((f, i) => `set \${${i + 1}:${f.name}} to packet.${f.name}`)
      .join('\n');
    return {
      label: 'scaffold packet fields',
      kind: CompletionItemKind.Snippet,
      detail: `bind all ${info.fields.length} fields of ${simpleName}`,
      documentation: {
        kind: MarkupKind.Markdown,
        value:
          `Inserts a \`set … to packet.<field>\` line for every field of ` +
          `\`${simpleName}\`:\n\n` +
          '```swoftlang\n' +
          info.fields.map((f) => `set ${f.name} to packet.${f.name}  // ${f.type}`).join('\n') +
          '\n```',
      },
      insertText: body,
      insertTextFormat: InsertTextFormat.Snippet,
      sortText: '0scaffold',
      data: -1,
    };
  };

  const analyze = (text: string): ScriptContext => {
    // enclosing `event <Name> { }` via a brace stack (skip strings/comments)
    const stack: (string | null)[] = [];
    let inStr = false;
    for (let i = 0; i < text.length; i++) {
      const c = text[i];
      if (inStr) {
        if (c === '\\') i++;
        else if (c === '"') inStr = false;
        continue;
      }
      if (c === '"') inStr = true;
      else if (c === '/' && text[i + 1] === '/') {
        while (i < text.length && text[i] !== '\n') i++;
      } else if (c === '{') {
        const back = text.slice(Math.max(0, i - 80), i);
        const em = /\bevent\s+([A-Za-z_]\w*)\s*$/.exec(back);
        stack.push(em ? `event:${em[1]}` : null);
      } else if (c === '}') stack.pop();
    }
    let event: string | undefined;
    for (let k = stack.length - 1; k >= 0; k--) {
      const l = stack[k];
      if (l && l.startsWith('event:')) {
        event = l.slice('event:'.length);
        break;
      }
    }

    // argTypes from the last `arguments { … }` block seen before the cursor
    const argTypes: Record<string, string> = {};
    const argBlockRe = /\barguments\s*\{/g;
    let am: RegExpExecArray | null;
    let lastBody = '';
    while ((am = argBlockRe.exec(text))) {
      let j = am.index + am[0].length;
      let d = 1;
      while (j < text.length && d > 0) {
        if (text[j] === '{') d++;
        else if (text[j] === '}') d--;
        j++;
      }
      lastBody = text.slice(am.index + am[0].length, j - 1);
    }
    const argRe = /(?:^|\n)\s*([A-Za-z_]\w*)\s*:\s*([A-Za-z_][\w]*)/g;
    let pm: RegExpExecArray | null;
    while ((pm = argRe.exec(lastBody))) argTypes[pm[1]] = pm[2];

    // varTypes from `spawn mob|entity … as NAME` and `set NAME to builtin(…)`
    const varTypes: Record<string, string> = {};
    let vm: RegExpExecArray | null;
    const spawnRe = /\bspawn\s+(mob|entity)\b[^\n]*?\bas\s+([A-Za-z_]\w*)/g;
    while ((vm = spawnRe.exec(text))) varTypes[vm[2]] = vm[1] === 'mob' ? 'Mob' : 'Entity';
    const setRe = /\bset\s+([A-Za-z_]\w*)\s+to\s+([A-Za-z_]\w*)\s*\(/g;
    while ((vm = setRe.exec(text))) {
      const rt = builtinReturn.get(vm[2]);
      if (rt) varTypes[vm[1]] = rt;
    }

    const block = enclosingBlock(text);
    const packetClass = findEnclosingPacketClass(text);

    return { event, argTypes, varTypes, block, packetClass };
  };

  const getCompletions = (
    prefix: string,
    depth: number,
    locals: string[] = [],
    ctx: ScriptContext = {},
  ): CompletionItem[] => {
    // 0) `Packet { on "<CURSOR>" }` — complete packet CLASS names (inbound first).
    //    The `on "…"` block is not yet open, so the enclosing block is `Packet`.
    if (
      packetClassItems.length &&
      ctx.block === 'Packet' &&
      /\bon\s+"[^"]*$/.test(prefix)
    ) {
      return packetClassItems;
    }
    // 1) Inside a string: only MiniMessage tags right after `<`, otherwise nothing.
    if (inUnclosedString(prefix)) {
      if (/<\/?\w*$/.test(prefix)) return withGroup(minimessageItems, '0');
      return [];
    }
    // 2) Property access after a dot — offer ONLY the receiver type's properties.
    const chainM = CHAIN_RE.exec(prefix);
    if (chainM) {
      // `packet.<field>` inside a known Packet handler -> that class's fields.
      if (chainM[1].trim() === 'packet' && ctx.packetClass) {
        return packetFieldItems(ctx.packetClass);
      }
      const type = resolveReceiverType(chainM[1], ctx);
      if (!type) return []; // can't infer the receiver -> nothing, not the wall
      return propsForType(type);
    }
    // 3) Config property value: `<key>: ` with known values -> only those.
    const pv = PROP_VALUE_RE.exec(prefix);
    if (pv) {
      const vs = valuesForKey(pv[1]);
      if (vs) return withGroup(enumItems(vs.group, vs.values), '0');
    }
    // 4) Type position (after `is [a]`, inside `<…>`, or after a `:` annotation).
    if (isTypeContext(prefix)) return withGroup(typeItems, '0');
    // 5) Statement start — only leading whitespace and a partial word.
    if (/^\s*\w*$/.test(prefix)) {
      if (depth <= 0) return dedupeByLabel(withGroup(declItems, '0'));

      // 5a) Inside an `attributes { }` block: the attribute keys, nothing else.
      if (ctx.block === 'attributes') {
        const keys = [...(enums.attribute_keys || []), ...(enums.item_attribute_keys || [])];
        return dedupeByLabel(withGroup(enumItems('attribute', keys), '0'));
      }

      // 5b) Inside a declaration body (item/mob/npc/…): config keys + inline
      //     handlers + tags/attributes namespaces come first, then the usual
      //     statement palette so nothing is lost.
      const head: CompletionItem[] = [];
      if (ctx.block && HANDLER_HOST.has(ctx.block)) {
        head.push(
          ...withGroup(configKeysFor(ctx.block), '0'),
          ...withGroup(handlerItems, '1'),
          ...withGroup(namespaceItems, '1'),
        );
      }
      // 5b') Inside a `Packet { on "Class" { } }` handler: surface the bound
      //      `packet` receiver and a one-shot "scaffold all fields" snippet
      //      before the general palette.
      if (ctx.packetClass && getPacketInfo(ctx.packetClass)) {
        const scaffold = packetScaffoldItem(ctx.packetClass);
        head.push(
          ...withGroup(
            [
              {
                label: 'packet',
                kind: CompletionItemKind.Variable,
                detail: `the inbound ${ctx.packetClass}`,
                data: -1,
              },
              ...(scaffold ? [scaffold] : []),
            ],
            '0',
          ),
        );
      }
      // 5c) The user's own variables, then statement keywords / builtins / consts.
      return dedupeByLabel([
        ...head,
        ...withGroup(localItems(locals), '2'),
        ...withGroup(statementKwItems, '3'),
        ...withGroup(builtinItems, '4'),
        ...withGroup(constantItems, '5'),
      ]);
    }
    // 6) General expression position — local variables first (what the user wants),
    //    then builtins, constants, and word operators/connectives.
    return dedupeByLabel([
      ...withGroup(localItems(locals), '0'),
      ...withGroup(builtinItems, '1'),
      ...withGroup(constantItems, '2'),
      ...withGroup(operatorItems, '3'),
      ...withGroup(connectiveItems, '4'),
    ]);
  };

  const resolve = (item: CompletionItem): CompletionItem => {
    const idx = item.data as number;
    if (typeof idx !== 'number' || idx < 0) return item;
    const s = data.symbols[idx];
    if (s) {
      if (s.signatures && s.signatures.length > 1) {
        item.documentation = {
          kind: MarkupKind.Markdown,
          value: '```swoftlang\n' + s.signatures.join('\n') + '\n```' + (s.doc ? '\n\n' + s.doc : ''),
        };
      } else if (s.doc) {
        item.documentation = s.doc;
      }
    }
    return item;
  };

  return { getCompletions, resolve, analyze, getPacketInfo, getPacketField };
}
