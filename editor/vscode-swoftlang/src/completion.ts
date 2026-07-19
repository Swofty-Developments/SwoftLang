/*
 * Context-aware completion for SwoftLang.
 *
 * Instead of dumping all ~400 symbols on every keystroke, we inspect the text
 * on the line before the cursor and return only the bucket that can legally
 * appear there. This module is deliberately free of any LSP connection state so
 * it can be driven directly from a headless test.
 *
 *   - after `.`                       -> property names only
 *   - after `:` / inside `<…>` / `is` -> types only
 *   - inside a "…" string             -> nothing (MiniMessage tags after `<`)
 *   - statement start, inside a block  -> statement keywords + builtins + consts
 *   - statement start, at top level    -> declaration keywords
 *   - any other expression position    -> builtins + consts + word operators
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
}

// What the analyzer can work out about the cursor's surroundings, used to infer
// the type of a `.`-receiver so property completion is owner-precise.
export interface ScriptContext {
  event?: string; // enclosing `event <Name> { }` handler name, e.g. 'PlayerJoin'
  argTypes?: Record<string, string>; // command `arguments { name: Type }`
  varTypes?: Record<string, string>; // locals with an inferable type
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
}

// Nominal subtype edges: a receiver of the subtype also exposes supertype props.
const SUPERTYPES: Record<string, string[]> = {
  Mob: ['Entity'],
  Player: ['OfflinePlayer'],
};

// Snippet templates for constructs where a fill-in-the-blanks body genuinely
// helps. Trivial keywords (halt/else/true/none/…) stay plain text.
const SNIPPETS: Record<string, string> = {
  send: 'send "$1" to ${2:sender}',
  broadcast: 'broadcast "$1"',
  teleport: 'teleport $1 to $2',
  set: 'set ${1:name} to $2',
  if: 'if $1 {\n\t$0\n}',
  while: 'while $1 {\n\t$0\n}',
  loop: 'loop ${1:10} times as ${2:i} {\n\t$0\n}',
  function: 'function ${1:name}(${2:x: Integer}) {\n\t$0\n}',
  command: 'command "${1:name}" {\n\texecute {\n\t\t$0\n\t}\n}',
  event: 'event ${1:PlayerJoin} {\n\texecute {\n\t\t$0\n\t}\n}',
  mob: 'mob "${1:id}" {\n\ttype: "${2:ZOMBIE}"\n\t$0\n}',
  show: 'show ${1|scoreboard,tablist,bossbar|} "$2" to $3',
  spawn: 'spawn $1',
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
      return CompletionItemKind.Event;
    case 'property':
      return CompletionItemKind.Property;
    case 'enum':
      return CompletionItemKind.EnumMember;
    default:
      return CompletionItemKind.Text;
  }
}

// Sub-buckets for the ~62 symbols tagged plainly as `keyword`.
const STATEMENT_KEYWORDS = new Set([
  'if', 'else', 'halt', 'loop', 'while', 'return', 'wait', 'spawn', 'call', 'repeat',
  'stop', 'send', 'teleport', 'set', 'cancel', 'broadcast', 'open', 'close', 'replace',
  'show', 'hide', 'update', 'title', 'subtitle', 'actionbar', 'clear', 'line', 'blank',
  'entry', 'fill', 'give', 'dispense', 'mount', 'dismount', 'launch', 'remove', 'reset',
  'belowname', 'go', 'back',
]);
const CONNECTIVE_KEYWORDS = new Set(['to', 'at', 'with', 'for', 'every', 'manual', 'as', 'times']);
// Declaration keywords that live at top level but are not in the symbol table.
const EXTRA_TOPLEVEL = ['storage', 'persistent', 'import', 'export', 'fishing_loot'];
// A small, curated MiniMessage palette offered inside strings after `<`.
const MINIMESSAGE_TAGS = [
  'red', 'green', 'blue', 'yellow', 'aqua', 'gold', 'gray', 'white', 'black',
  'dark_red', 'dark_green', 'dark_blue', 'dark_aqua', 'dark_gray', 'dark_purple',
  'light_purple', 'bold', 'italic', 'underlined', 'strikethrough', 'obfuscated',
  'reset', 'newline',
];

// Config property key -> its exact allowed bareword values. Verified against
// compiler/lib/registry.ml (and parse_decl.ml/parse_ui.ml for auth/backend/
// numbers). Keys not in this table (host/port/name/title/…) fall through to the
// generic context logic rather than the enum bucket.
const PROPERTY_VALUES: Record<string, string[]> = {
  numbers: ['hidden', 'shown'],
  auth: ['mojang', 'velocity', 'bungeecord', 'offline'],
  backend: ['files', 'sqlite', 'mysql', 'mongodb'],
  ai: ['melee', 'passive', 'none'],
  rarity: ['common', 'uncommon', 'rare', 'epic'],
  medium: ['water', 'lava'],
  activation: ['right_click', 'left_click'],
  color: ['pink', 'blue', 'red', 'green', 'yellow', 'purple', 'white'], // bossbar_colors
  style: ['progress', 'notched_6', 'notched_10', 'notched_12', 'notched_20'], // bossbar_styles
  skin: ['green', 'gray', 'cyan', 'blue', 'purple', 'orange'], // tablist_skins
  lighting: ['true', 'false'],
  glint: ['true', 'false'],
  update: ['manual'], // the other form `every <n> ticks|seconds` is left to the user
  weather: ['clear', 'rain', 'thunder'],
  gamemode: ['survival', 'creative', 'adventure', 'spectator'],
  billboard: ['fixed', 'vertical', 'horizontal', 'center'],
  alignment: ['left', 'center', 'right'],
  filter: ['left', 'right', 'any'], // item on_click filters
  method: ['GET', 'POST', 'PUT', 'DELETE', 'ANY'],
  frame: ['task', 'goal', 'challenge'],
  glow_color: [
    'black', 'dark_blue', 'dark_green', 'dark_aqua', 'dark_red', 'dark_purple', 'gold', 'gray',
    'dark_gray', 'blue', 'green', 'aqua', 'red', 'light_purple', 'yellow', 'white',
  ], // nametag_colors (NamedTextColor)
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

export function createCompletionEngine(data: SymData): CompletionEngine {
  const buildItem = (s: Sym, idx: number): CompletionItem => {
    const item: CompletionItem = { label: s.name, kind: completionKind(s.kind), data: idx };
    if (s.kind === 'builtin' && s.signature) item.detail = s.signature;
    else if (s.kind === 'property' && s.owner) {
      item.detail = `${s.owner}.${s.name}: ${s.type}${s.writable ? '' : ' (read-only)'}`;
    } else if (s.kind === 'enum' && s.owner) item.detail = `${s.owner} value`;
    else item.detail = s.kind;
    if (s.doc) item.documentation = s.doc;
    // Snippet body only for statements/declarations — never a like-named property.
    if ((s.kind === 'keyword' || s.kind === 'declaration') && SNIPPETS[s.name]) {
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
      // properties are offered owner-filtered via propsByOwner, not here.
      case 'keyword':
        if (STATEMENT_KEYWORDS.has(s.name)) statementKwItems.push(item);
        else if (CONNECTIVE_KEYWORDS.has(s.name)) connectiveItems.push(item);
        break;
      // events / enums are intentionally not offered from generic contexts.
      default:
        break;
    }
  });
  for (const name of EXTRA_TOPLEVEL) {
    declItems.push({ label: name, kind: CompletionItemKind.Class, detail: 'declaration', data: -1 });
  }
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

    return { event, argTypes, varTypes };
  };

  const getCompletions = (
    prefix: string,
    depth: number,
    locals: string[] = [],
    ctx: ScriptContext = {},
  ): CompletionItem[] => {
    // 1) Inside a string: only MiniMessage tags right after `<`, otherwise nothing.
    if (inUnclosedString(prefix)) {
      if (/<\/?\w*$/.test(prefix)) return withGroup(minimessageItems, '0');
      return [];
    }
    // 2) Property access after a dot — offer ONLY the receiver type's properties.
    const chainM = CHAIN_RE.exec(prefix);
    if (chainM) {
      const type = resolveReceiverType(chainM[1], ctx);
      if (!type) return []; // can't infer the receiver -> nothing, not the wall
      return propsForType(type);
    }
    // 3) Config property value: `<key>: ` with a known enum -> only those values.
    const pv = PROP_VALUE_RE.exec(prefix);
    if (pv && PROPERTY_VALUES[pv[1]]) {
      const key = pv[1];
      const items = PROPERTY_VALUES[key].map<CompletionItem>((v) => ({
        label: v,
        kind: CompletionItemKind.EnumMember,
        detail: `${key} value`,
        data: -1,
      }));
      return withGroup(items, '0');
    }
    // 4) Type position (after `is [a]`, inside `<…>`, or after a `:` annotation).
    if (isTypeContext(prefix)) return withGroup(typeItems, '0');
    // 5) Statement start — only leading whitespace and a partial word.
    if (/^\s*\w*$/.test(prefix)) {
      if (depth <= 0) return dedupeByLabel(withGroup(declItems, '0'));
      // Inside a block: the user's own variables first, then statement keywords.
      return dedupeByLabel([
        ...withGroup(localItems(locals), '0'),
        ...withGroup(statementKwItems, '1'),
        ...withGroup(builtinItems, '2'),
        ...withGroup(constantItems, '3'),
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

  return { getCompletions, resolve, analyze };
}
