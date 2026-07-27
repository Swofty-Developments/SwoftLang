#!/usr/bin/env python3
"""
Regenerate the SwoftLang TextMate grammar from editor/swoftlang-symbols.json.

Single source of truth: the symbol dump. This script categorizes every symbol
precisely (control / declaration / statement keywords, handler names, builtin
functions, types, enum constants, namespaces, entity property names) into its
own TextMate scope, then writes BOTH grammar copies byte-identically:

  * docs/.vitepress/swoftlang.tmLanguage.json
  * editor/vscode-swoftlang/syntaxes/swoftlang.tmLanguage.json

The hand-written string / number / comment / interpolation machinery is kept
verbatim (declared inline below). Run:  python3 editor/generate-grammar.py
It asserts that every symbol from the dump appears in the emitted grammar and
that both files are valid JSON and identical.
"""

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SYMBOLS = os.path.join(HERE, "swoftlang-symbols.json")
OUT_DOCS = os.path.join(ROOT, "docs", ".vitepress", "swoftlang.tmLanguage.json")
OUT_EXT = os.path.join(
    ROOT, "editor", "vscode-swoftlang", "syntaxes", "swoftlang.tmLanguage.json"
)

# ---------------------------------------------------------------------------
# Categorization of the flat `keywords` array from the dump. Every entry of
# that array must land in exactly one bucket (asserted below), so nothing is
# silently dropped and nothing is miscolored.
# ---------------------------------------------------------------------------

CONTROL_KW = [
    "if", "else", "loop", "while", "times", "return", "repeat",
    "stop", "halt", "wait", "cancel", "call", "go", "as",
    # §5 struct schema-migration soft keywords (schema: N / migrate to N { }).
    "schema", "migrate",
    # v1.8.0 futures: await/any (all/of/spawn live in other buckets); Future is
    # a generic type container below. v1.9.0 removed `when … is ready`, so
    # `when`/`ready` are no longer keywords.
    "await", "any",
]
# declaration / binding keywords that live in the flat keywords[] list
DECL_KW = ["command", "event", "function", "schedule", "on", "every"]
IMPORT_KW = ["import", "export"]
STORAGE_KW = ["var", "set"]
STATEMENT_KW = [
    "send", "broadcast", "reply", "teleport", "spawn", "launch", "give",
    "show", "hide", "place", "remove", "add", "clear", "delete", "create",
    "open", "close", "play", "move", "save", "load", "unload", "update",
    "reset", "title", "actionbar", "fill", "clone", "replace", "despawn",
    "destroy", "mount", "dismount", "dispense", "draw", "skin", "name",
    "line", "entry", "blank", "belowname", "fade", "damage", "knock",
    "apply", "shoot",
]
OPERATOR_WORD_KW = ["is", "not", "and", "or", "Either", "contains"]
CONNECTIVE_KW = ["to", "in", "of"]
BOOLEAN_KW = ["true", "false"]
TARGET_KW = ["all", "players"]

# ---------------------------------------------------------------------------
# v1.9.0 custom mob AI (dump key 'ai_keywords'). Soft keywords the parser
# matches on IDENT text; categorized here into their coloring buckets so the
# whole AI surface reads consistently. These three buckets must partition the
# dump's ai_keywords array exactly (asserted below), mirroring the keywords[]
# partition, so nothing is silently dropped or miscolored.
#   * lifecycle blocks -> handler scope (same family as on_click / on_tick)
#   * navigator verbs  -> statement scope (path / stop pathing / look at)
#   * selector/query   -> control scope (ai / goals / within / closest / ...)
AI_HANDLER_KW = ["should_start", "on_start", "on_tick", "should_end", "on_end"]
AI_STATEMENT_KW = ["path", "pathing", "look", "speed"]
AI_CONTROL_KW = [
    "ai", "goals", "within", "priority", "reached", "closest", "hostile",
    "attacker", "navigating",
]

# ---------------------------------------------------------------------------
# v1.10.0 network persistence (dump key 'persistence_keywords'). Soft keywords
# the parser matches on IDENT text, categorized here into their coloring
# buckets. These five buckets must partition the dump's persistence_keywords
# array exactly (asserted below), mirroring the keywords[]/ai_keywords[]
# partitions, so nothing is silently dropped or miscolored.
#   * storage-block keys   -> attribute-name (the `key:` half of a config line)
#   * storage-block values -> enum constants (standalone/network/kick/redis/...)
#   * change-handler heads -> handler scope (same family as on_click / on_tick)
#   * atomic write ops     -> statement scope (subtract/append/grant; `add`
#                             already ships as a statement verb)
#   * handler bound names  -> language variables (same family as player/event)
PERSIST_KEY_KW = [
    "backend", "flush", "mode", "on_handoff_failure", "coordinator",
    "host", "port", "database", "user", "password",
]
# the subset of PERSIST_KEY_KW that lives inside a `mysql { } / mongodb { }`
# connection block rather than directly in the `storage { }` body
BACKEND_CONN_KW = ["host", "port", "database", "user", "password"]
PERSIST_VALUE_KW = [
    "standalone", "network", "kick", "redis",
    "files", "sqlite", "mysql", "mongodb",
]
PERSIST_HANDLER_KW = ["on_change", "on_entry_change"]
PERSIST_STATEMENT_KW = ["subtract", "append", "grant"]
PERSIST_BIND_KW = ["old", "new", "caused_here", "key", "player"]
# `key: value` pairs whose value set is fixed, so the value keeps a precise enum
# scope even when more text follows it (`backend: mysql { … }`,
# `coordinator: redis "…"`) and the generic property-key rule can't reach it.
PERSIST_KEY_VALUES = {
    "mode": ["standalone", "network"],
    "backend": ["files", "sqlite", "mysql", "mongodb"],
    "on_handoff_failure": ["kick"],
    "coordinator": ["redis"],
}

# ---------------------------------------------------------------------------
# Static supplementary vocabulary (NOT in the dump, but real structural words
# used across the .sw corpus). Kept here so regenerating never regresses the
# coloring of block sections, prepositions, parameter words or time units.
# ---------------------------------------------------------------------------

EXTRA_OPERATOR_WORDS = ["exists", "otherwise", "missing"]
BLOCK_SECTION_WORDS = [
    "execute", "arguments", "drops", "lore", "state", "lines", "column",
    "editable", "paginate", "render", "slot", "slots", "refresh", "border",
    "source", "prev_slot", "next_slot", "look_at_players", "http", "fishing",
    "catch", "grid", "first", "manual", "async", "packet", "particle",
    "projectile",
]
PREPOSITION_WORDS = [
    "with", "at", "for", "from", "by", "away", "into", "toward", "on",
    "subtitle", "stay",
]
PARAMETER_WORDS = [
    "weight", "chance", "amount", "count", "offset", "code", "message",
    "strength",
]
UNIT_WORDS = ["ticks", "tick", "seconds", "second", "millis", "milli"]
EXTRA_TARGETS = ["sender", "self", "killer", "victim"]
EXTRA_CONSTANTS = ["none"]
EXTRA_TYPE_ALIASES = ["Number"]

# Enum-group -> list of trigger regexes preceding the value capture. Colon
# triggers are anchored at line start (^\s*) so a `key: value` enum wins the
# leftmost-match tie against the generic property-key rule and thus gets its
# precise per-group scope (and colors UPPERCASE values the generic rule skips).
# Keyword triggers (e.g. `with skin green`) match mid-line.
ENUM_TRIGGERS = {
    "gamemode": [r"^\s*(gamemode)\s*(:)\s*"],
    "rarity": [r"^\s*(rarity)\s*(:)\s*"],
    "ai": [r"^\s*(ai)\s*(:)\s*"],
    "billboard": [r"^\s*(billboard)\s*(:)\s*"],
    "alignment": [r"^\s*(alignment)\s*(:)\s*"],
    "weather": [r"^\s*(weather)\s*(:)\s*"],
    "pose": [r"^\s*(pose)\s*(:)\s*"],
    "hand": [r"^\s*(hand)\s*(:)\s*"],
    "block_face": [r"^\s*(face|block_face)\s*(:)\s*"],
    "bossbar_color": [r"^\s*(color)\s*(:)\s*"],
    "bossbar_style": [r"^\s*(style)\s*(:)\s*"],
    "nametag_color": [r"^\s*(color)\s*(:)\s*", r"\b(skin)\s+"],
    "api_method": [r"^\s*(method)\s*(:)\s*"],
    "toast_frame": [r"^\s*(frame)\s*(:)\s*"],
    "fishing_medium": [r"^\s*(medium)\s*(:)\s*"],
    "projectile_type": [r"^\s*(projectile_type)\s*(:)\s*"],
    "damage_types": [r"^\s*(damage_type)\s*(:)\s*"],
    "effect_types": [r"^\s*(effect|effect_type)\s*(:)\s*"],
    "modifier_operations": [r"^\s*(operation|operations)\s*(:)\s*"],
}
# Enum groups whose every value is already embedded (and correctly scoped) by
# the entity-property or effect_types patterns; no dedicated pattern needed.
ENUM_SKIP = {"attribute_keys", "item_attribute_keys"}


def alt(words):
    """Regex alternation, longest-first so `\\b`-guarded prefixes never shadow."""
    uniq = sorted(set(words), key=lambda w: (-len(w), w))
    return "|".join(re.escape(w) for w in uniq)


def kw_pattern(name, words, *, no_dot=False):
    tail = r"\b(?!\s*\.)" if no_dot else r"\b"
    return {"name": name, "match": r"\b(" + alt(words) + r")" + tail}


def main():
    with open(SYMBOLS, encoding="utf-8") as f:
        sym = json.load(f)

    # sanity: the flat keyword buckets must partition keywords[] exactly.
    buckets = (
        CONTROL_KW + DECL_KW + IMPORT_KW + STORAGE_KW + STATEMENT_KW
        + OPERATOR_WORD_KW + CONNECTIVE_KW + BOOLEAN_KW + TARGET_KW
    )
    assert sorted(buckets) == sorted(sym["keywords"]), (
        "keyword partition mismatch:\n  extra="
        + str(sorted(set(buckets) - set(sym["keywords"])))
        + "\n  missing="
        + str(sorted(set(sym["keywords"]) - set(buckets)))
    )

    # v1.9.0 AI vocabulary: the three AI buckets must partition ai_keywords[].
    ai_keywords = sym.get("ai_keywords", [])
    ai_buckets = AI_HANDLER_KW + AI_STATEMENT_KW + AI_CONTROL_KW
    assert sorted(ai_buckets) == sorted(ai_keywords), (
        "ai_keyword partition mismatch:\n  extra="
        + str(sorted(set(ai_buckets) - set(ai_keywords)))
        + "\n  missing="
        + str(sorted(set(ai_keywords) - set(ai_buckets)))
    )

    # v1.10.0 persistence vocabulary: the five buckets must partition
    # persistence_keywords[].
    persist_keywords = sym.get("persistence_keywords", [])
    persist_buckets = (
        PERSIST_KEY_KW + PERSIST_VALUE_KW + PERSIST_HANDLER_KW
        + PERSIST_STATEMENT_KW + PERSIST_BIND_KW
    )
    assert sorted(persist_buckets) == sorted(persist_keywords), (
        "persistence_keyword partition mismatch:\n  extra="
        + str(sorted(set(persist_buckets) - set(persist_keywords)))
        + "\n  missing="
        + str(sorted(set(persist_keywords) - set(persist_buckets)))
    )

    handlers = sym["handlers"]
    builtins = sym["builtins"]
    decls = sym["declarations"]
    namespaces = sym["namespaces"]
    # capitalized OOP receiver block heads (Player { }, Npc { }, Packet { }, ...)
    receivers = sym.get("receivers", [])
    # natural-language collection operators (size of / m has k / sorted l / ...).
    # Soft keywords in the compiler, advertised under their own dump key so they
    # get a distinct grammar scope without being globally reserved.
    collection_ops = sym.get("collection_ops", [])
    # §4 struct-field annotations (@EventReceiver): the only field modifiers.
    annotations = sym.get("annotations", [])

    # type primitives = all declared types minus the generic containers
    containers = ["Either", "Optional", "List", "Map", "Future"]
    primitives = [t for t in sym["types"] if t not in containers] + EXTRA_TYPE_ALIASES

    # union of every entity property name across every type table
    prop_names = []
    for tname, props in sym["properties"].items():
        for p in props:
            prop_names.append(p["name"])
    prop_names = sorted(set(prop_names) - set(namespaces))

    # ---- enum value patterns ------------------------------------------------
    enum_patterns = []
    for group, values in sym["enums"].items():
        if group in ENUM_SKIP:
            continue
        if group == "entity_types":
            # SCREAMING_CASE ids: only ever appear bare very rarely, safe to
            # match unconditionally; normally they sit inside strings (already
            # consumed by the string rule) so this mostly just documents them.
            enum_patterns.append({
                "name": "constant.other.enum.entity-type.swoftlang",
                "match": r"\b(" + alt(values) + r")\b",
            })
            continue
        triggers = ENUM_TRIGGERS.get(group, [r"^\s*(" + group + r")\s*(:)\s*"])
        for trig in triggers:
            ncap = re.compile(trig).groups
            match = trig + r"(" + alt(values) + r")\b"
            caps = {}
            # trigger capture groups: keyword-ish -> attribute-name, ':' -> sep
            for i in range(1, ncap + 1):
                # detect whether this group is the ':' separator
                caps[str(i)] = {"name": "punctuation.separator.key-value.swoftlang"}
            # first trigger group is always the key/keyword
            caps["1"] = {"name": "entity.other.attribute-name.property.swoftlang"}
            caps[str(ncap + 1)] = {
                "name": "constant.other.enum." + group.replace("_", "-") + ".swoftlang"
            }
            enum_patterns.append({"match": match, "captures": caps})

    # ---- assemble repository ------------------------------------------------
    repo = {}

    repo["comments"] = {
        "patterns": [
            {
                "name": "comment.line.double-slash.swoftlang",
                "begin": "//",
                "beginCaptures": {
                    "0": {"name": "punctuation.definition.comment.swoftlang"}
                },
                "end": "$",
            },
            {
                "name": "comment.block.swoftlang",
                "begin": r"/\*",
                "beginCaptures": {
                    "0": {"name": "punctuation.definition.comment.begin.swoftlang"}
                },
                "end": r"\*/",
                "endCaptures": {
                    "0": {"name": "punctuation.definition.comment.end.swoftlang"}
                },
            },
        ]
    }

    repo["strings"] = {
        "name": "string.quoted.double.swoftlang",
        "begin": "\"",
        "beginCaptures": {
            "0": {"name": "punctuation.definition.string.begin.swoftlang"}
        },
        "end": "\"",
        "endCaptures": {
            "0": {"name": "punctuation.definition.string.end.swoftlang"}
        },
        "patterns": [
            {"name": "constant.character.escape.swoftlang", "match": r"\\."},
            {
                "name": "constant.other.color.minimessage.swoftlang",
                "match": r"</?[a-zA-Z_#][a-zA-Z0-9_#:]*>",
            },
            {
                "name": "meta.template.expression.swoftlang",
                "begin": r"\$\{",
                "beginCaptures": {
                    "0": {
                        "name": "punctuation.definition.template-expression.begin.swoftlang"
                    }
                },
                "end": r"\}",
                "endCaptures": {
                    "0": {
                        "name": "punctuation.definition.template-expression.end.swoftlang"
                    }
                },
                "patterns": [{"include": "#interpolation-expression"}],
            },
        ],
    }

    repo["interpolation-expression"] = {
        "patterns": [
            {"include": "#builtins"},
            {"include": "#namespace-accessor"},
            {"include": "#property-accessor"},
            {"include": "#operator-words"},
            {"include": "#types"},
            {"include": "#user-types"},
            {"include": "#constants"},
            {"include": "#numbers"},
            {"include": "#operators"},
            {"include": "#function-calls"},
            *([{"include": "#collection-ops"}] if collection_ops else []),
            {"include": "#variables"},
            {"include": "#punctuation"},
        ]
    }

    repo["builtins"] = {
        "patterns": [
            {
                "comment": "builtin function: name immediately followed by '('",
                "name": "support.function.builtin.swoftlang",
                "match": r"\b(" + alt(builtins) + r")\b(?=\s*\()",
            }
        ]
    }

    repo["handlers"] = {
        "patterns": [
            {
                "comment": "event handler names (on_tick, on_click, tick, ...)",
                "name": "keyword.other.handler.swoftlang",
                "match": r"\b(" + alt(handlers) + r")\b(?=\s*[({])",
            }
        ]
    }

    repo["namespaces"] = {
        "patterns": [
            {
                "comment": "namespace block headers: tags: { } / tasks: { } / attributes: { } (canonical colon form; bare form still accepted)",
                "name": "storage.type.namespace.swoftlang",
                "match": r"^\s*(" + alt(namespaces) + r")\b(?=\s*:?\s*\{)",
                "captures": {
                    "1": {"name": "storage.type.namespace.swoftlang"}
                },
            }
        ]
    }

    repo["namespace-accessor"] = {
        "patterns": [
            {
                "comment": ".tags / .tasks / .attributes namespace access",
                "match": r"(\.)(" + alt(namespaces) + r")\b",
                "captures": {
                    "1": {"name": "punctuation.accessor.swoftlang"},
                    "2": {"name": "entity.other.namespace.swoftlang"},
                },
            }
        ]
    }

    repo["property-accessor"] = {
        "patterns": [
            {
                "comment": "entity property access after '.' (not a method call)",
                "match": r"(\.)(" + alt(prop_names) + r")\b(?!\s*\()",
                "captures": {
                    "1": {"name": "punctuation.accessor.swoftlang"},
                    "2": {"name": "variable.other.property.swoftlang"},
                },
            }
        ]
    }

    repo["declarations"] = {
        "patterns": [
            {
                "match": r"\b(event)\s+([A-Za-z_][A-Za-z0-9_]*)",
                "captures": {
                    "1": {"name": "storage.type.declaration.swoftlang"},
                    "2": {"name": "entity.name.class.event.swoftlang"},
                },
            },
            {
                "match": r"\b(async\s+function|function)\s+([A-Za-z_][A-Za-z0-9_]*)",
                "captures": {
                    "1": {"name": "storage.type.declaration.swoftlang"},
                    "2": {"name": "entity.name.function.swoftlang"},
                },
            },
            # a struct declaration names a nominal type (§1): color the
            # Capitalized type name as a class, like 'event Name'
            {
                "match": r"\b(struct)\s+([A-Za-z_][A-Za-z0-9_]*)",
                "captures": {
                    "1": {"name": "storage.type.declaration.swoftlang"},
                    "2": {"name": "entity.name.class.swoftlang"},
                },
            },
            # block-declaration keywords (item, mob, npc, gui, ...) + the named
            # def introducers (command, event, function, schedule)
            {
                "name": "storage.type.declaration.swoftlang",
                "match": r"\b(" + alt(decls + DECL_KW) + r")\b(?!\s*\.)",
            },
        ]
    }

    # capitalized receiver block heads: Player { }, Entity { }, Npc { },
    # Hologram { }, Packet { } — colored where they introduce a receiver block.
    repo["receivers"] = {
        "patterns": [
            {
                "comment": "OOP receiver block head (Capitalized name before '{')",
                "name": "storage.type.receiver.swoftlang",
                "match": r"\b(" + alt(receivers) + r")\b(?=\s*\{)",
            }
        ]
    }

    repo["import"] = {
        "patterns": [
            kw_pattern("keyword.control.import.swoftlang", IMPORT_KW)
        ]
    }

    repo["storage-modifiers"] = {
        "patterns": [
            kw_pattern("storage.modifier.swoftlang", STORAGE_KW + ["persistent"])
        ]
    }

    # §4 struct-field event-subject annotation: @EventReceiver marks a struct
    # field as the subject its reactive block reacts on. Colored as a modifier.
    if annotations:
        repo["annotations"] = {
            "patterns": [
                {
                    "comment": "reactive struct field modifier (§4): @EventReceiver",
                    "name": "storage.modifier.annotation.swoftlang",
                    "match": "(" + "|".join(re.escape(a) for a in annotations) + r")\b",
                }
            ]
        }

    repo["enums"] = {"patterns": enum_patterns}

    repo["property-keys"] = {
        "patterns": [
            {
                "comment": "key: bareword — value colored as an enum constant when the whole value is one lowercase word",
                "match": r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(:)(?!:)\s*([a-z][a-z0-9_]*)\s*(?=$|//)",
                "captures": {
                    "1": {"name": "entity.other.attribute-name.property.swoftlang"},
                    "2": {"name": "punctuation.separator.key-value.swoftlang"},
                    "3": {"name": "constant.other.enum.swoftlang"},
                },
            },
            {
                "match": r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*(:)(?!:)",
                "captures": {
                    "1": {"name": "entity.other.attribute-name.property.swoftlang"},
                    "2": {"name": "punctuation.separator.key-value.swoftlang"},
                },
            },
        ]
    }

    repo["types"] = {
        "patterns": [
            {
                "begin": r"\b(" + alt(containers) + r")\s*(<)",
                "beginCaptures": {
                    "1": {"name": "support.type.constructor.swoftlang"},
                    "2": {
                        "name": "punctuation.definition.typeparameters.begin.swoftlang"
                    },
                },
                "end": ">",
                "endCaptures": {
                    "0": {
                        "name": "punctuation.definition.typeparameters.end.swoftlang"
                    }
                },
                "patterns": [
                    {"include": "#types"},
                    {
                        "name": "punctuation.separator.typeparameters.swoftlang",
                        "match": r"[,|]",
                    },
                ],
            },
            {
                "name": "support.type.primitive.swoftlang",
                "match": r"\b(" + alt(primitives) + r")\b",
            },
        ]
    }

    repo["operator-words"] = {
        "patterns": [
            {
                "name": "keyword.operator.word.swoftlang",
                "match": r"\b(" + alt(OPERATOR_WORD_KW + EXTRA_OPERATOR_WORDS) + r")\b",
            }
        ]
    }

    # natural-language collection operators. Emitted only when the dump carries
    # them; placed after #keywords in the include order so words that are also
    # general connectives/section words (of, first) keep their established scope
    # and the collection-specific words (has, sorted, reversed, last) pick up
    # this scope. All are still present in the text for the coverage assertion.
    if collection_ops:
        repo["collection-ops"] = {
            "patterns": [
                {
                    "comment": "collection ops: size/keys/values of m, m has k, sorted/reversed l, first/last of l",
                    "name": "keyword.operator.collection.swoftlang",
                    "match": r"\b(" + alt(collection_ops) + r")\b",
                }
            ]
        }

    repo["keywords"] = {
        "patterns": [
            kw_pattern("keyword.control.swoftlang", CONTROL_KW),
            kw_pattern("keyword.other.statement.swoftlang", STATEMENT_KW),
            kw_pattern("keyword.other.handler.swoftlang", handlers),
            kw_pattern("keyword.other.block.swoftlang", BLOCK_SECTION_WORDS, no_dot=True),
            kw_pattern(
                "keyword.other.connective.swoftlang",
                CONNECTIVE_KW + PREPOSITION_WORDS + PARAMETER_WORDS,
            ),
            kw_pattern("constant.language.unit.swoftlang", UNIT_WORDS),
        ]
    }

    # v1.9.0 custom mob AI vocabulary. Emitted only when the dump carries it.
    # Lifecycle blocks color as handlers, navigator verbs as statements, and the
    # selector/query words as control keywords — so `ai`/`goal`/`should_start`/
    # `path … at speed`/`stop pathing`/`look at`/`within`/`priority`/`reached`/
    # `.navigating`/`closest`/`hostile`/`last attacker` all read consistently.
    if ai_keywords:
        repo["ai-keywords"] = {
            "patterns": [
                kw_pattern("keyword.other.handler.ai.swoftlang", AI_HANDLER_KW),
                kw_pattern("keyword.other.statement.ai.swoftlang", AI_STATEMENT_KW),
                kw_pattern("keyword.control.ai.swoftlang", AI_CONTROL_KW),
            ]
        }

    # v1.10.0 network-persistence vocabulary. Emitted only when the dump carries
    # it. Included ahead of #enums/#property-keys so a `storage { }` config line
    # keeps its precise storage scope (`mode: network`, `backend: mysql { }`,
    # `coordinator: redis "…"`, `on_handoff_failure: kick "…"`) instead of the
    # generic property-key coloring, and so `on_change`/`on_entry_change` read as
    # handlers and `subtract`/`append`/`grant` as statement verbs. The bound
    # names (old/new/key/caused_here/player) are language variables, emitted in
    # #variables alongside `event`/`args`/`mob`.
    if persist_keywords:
        persist_patterns = []
        # The shared-backend connection block. A begin/end rule (not a line
        # match) so `mysql { host: …, port: …, … }` colors its keys whether it is
        # written on one line or spread over many — a line-anchored `key:` rule
        # can only ever reach the first one.
        conn_body = [
            {
                "comment": "mysql/mongodb connection keys",
                "match": r"\b(" + alt(BACKEND_CONN_KW) + r")\s*(:)(?!:)",
                "captures": {
                    "1": {"name": "entity.other.attribute-name.storage.swoftlang"},
                    "2": {"name": "punctuation.separator.key-value.swoftlang"},
                },
            },
            {"include": "#comments"},
            {"include": "#strings"},
            {"include": "#builtins"},
            {"include": "#numbers"},
            {"include": "#function-calls"},
            {"include": "#punctuation"},
        ]
        backend_alt = alt(["mysql", "mongodb"])
        persist_patterns.append({
            "comment": "storage block: backend: mysql { … } / mongodb { … }",
            "begin": r"^\s*(backend)\s*(:)\s*(" + backend_alt + r")\s*(\{)",
            "beginCaptures": {
                "1": {"name": "entity.other.attribute-name.storage.swoftlang"},
                "2": {"name": "punctuation.separator.key-value.swoftlang"},
                "3": {"name": "constant.other.enum.storage-backend.swoftlang"},
                "4": {"name": "punctuation.section.block.swoftlang"},
            },
            "end": r"\}",
            "endCaptures": {"0": {"name": "punctuation.section.block.swoftlang"}},
            "patterns": conn_body,
        })
        persist_patterns.append({
            "comment": "bare shared-backend block (e.g. inside polar_storage_loader(mysql { … }))",
            "begin": r"\b(" + backend_alt + r")\s*(\{)",
            "beginCaptures": {
                "1": {"name": "constant.other.enum.storage.swoftlang"},
                "2": {"name": "punctuation.section.block.swoftlang"},
            },
            "end": r"\}",
            "endCaptures": {"0": {"name": "punctuation.section.block.swoftlang"}},
            "patterns": conn_body,
        })
        for key, values in PERSIST_KEY_VALUES.items():
            persist_patterns.append({
                "comment": f"storage block: {key}: <value>",
                "match": r"^\s*(" + re.escape(key) + r")\s*(:)\s*(" + alt(values) + r")\b",
                "captures": {
                    "1": {"name": "entity.other.attribute-name.storage.swoftlang"},
                    "2": {"name": "punctuation.separator.key-value.swoftlang"},
                    "3": {"name": "constant.other.enum.storage-" + key.replace("_", "-")
                          + ".swoftlang"},
                },
            })
        persist_patterns.append({
            "comment": "storage block config keys (backend/flush/mode/coordinator/host/…)",
            "match": r"^\s*(" + alt(PERSIST_KEY_KW) + r")\s*(:)(?!:)",
            "captures": {
                "1": {"name": "entity.other.attribute-name.storage.swoftlang"},
                "2": {"name": "punctuation.separator.key-value.swoftlang"},
            },
        })
        # backend / coordinator / handoff heads that take an argument: `mysql { }`,
        # `files "data/game"`, `redis "redis://…"`, `kick "…"`. Catches the same
        # words where no `key:` precedes them on the line (e.g. inside
        # `polar_storage_loader(mysql { … })`).
        persist_patterns.append({
            "comment": "storage backend / coordinator / handoff heads before their argument",
            "name": "constant.other.enum.storage.swoftlang",
            "match": r"\b(" + alt([w for w in PERSIST_VALUE_KW
                                   if w not in ("standalone", "network")])
                     + r")\b(?=\s*[{\"])",
        })
        persist_patterns.append({
            "comment": "declaration-attached change handlers (§4)",
            "name": "keyword.other.handler.persist.swoftlang",
            "match": r"\b(" + alt(PERSIST_HANDLER_KW) + r")\b(?=\s*\{)",
        })
        persist_patterns.append({
            "comment": "atomic persistent write ops (§3.2): subtract … from / append … to / grant … to",
            "name": "keyword.other.statement.persist.swoftlang",
            "match": r"\b(" + alt(PERSIST_STATEMENT_KW) + r")\b(?!\s*[.(])",
        })
        repo["persistence-keywords"] = {"patterns": persist_patterns}

    # PascalCase user type references (struct / reusable goal / custom-mob type
    # names): a Capitalized identifier that carries at least one lowercase letter,
    # so SCREAMING_CASE enum ids (ZOMBIE, IRON_GOLEM) are excluded and never
    # miscolored. Not a function call. Placed after the known-type / declaration /
    # receiver / enum rules so those keep their precise scopes; catches every
    # other PascalCase type reference (`target closest Guardian`, `goals: [ Chase
    # ]`, `mob Guardian { }`, a struct-typed field) that the fixed type list can't.
    repo["user-types"] = {
        "patterns": [
            {
                "comment": "PascalCase type reference (struct / goal type / custom mob type)",
                "name": "entity.name.type.swoftlang",
                "match": r"\b([A-Z][A-Za-z0-9_]*[a-z][A-Za-z0-9_]*)\b(?!\s*\()",
            }
        ]
    }

    repo["constants"] = {
        "patterns": [
            {
                "name": "constant.language.boolean.swoftlang",
                "match": r"\b(" + alt(BOOLEAN_KW) + r")\b",
            },
            {
                "name": "constant.language.swoftlang",
                "match": r"\b(" + alt(EXTRA_CONSTANTS) + r")\b",
            },
            {
                "name": "constant.language.target.swoftlang",
                "match": r"\b(" + alt(TARGET_KW + EXTRA_TARGETS) + r")\b",
            },
        ]
    }

    repo["numbers"] = {
        "name": "constant.numeric.swoftlang",
        "match": r"\b\d+(\.\d+)?\b",
    }

    repo["operators"] = {
        "patterns": [
            {
                "name": "keyword.operator.comparison.swoftlang",
                "match": r"==|!=|<=|>=|<(?![a-zA-Z<])|>",
            },
            {"name": "keyword.operator.logical.swoftlang", "match": r"&&|\|\||!"},
            {"name": "keyword.operator.range.swoftlang", "match": r"\.\."},
            {"name": "keyword.operator.arithmetic.swoftlang", "match": r"[+\-*/%]"},
            {"name": "keyword.operator.assignment.swoftlang", "match": r"="},
        ]
    }

    repo["function-calls"] = {
        "match": r"\b([A-Za-z_][A-Za-z0-9_]*)\s*(?=\()",
        "captures": {"1": {"name": "entity.name.function.call.swoftlang"}},
    }

    repo["variables"] = {
        "patterns": [
            {
                "name": "variable.language.swoftlang",
                "match": r"\b(event|args|state|player|mob|target|killer|victim|run|item|index|old_item|new_item|reason|click_type|hook_location|caught_item|caught_mob|packet|old|new|key|caused_here)\b(?=\.|\b)",
            },
            {
                "name": "variable.other.swoftlang",
                "match": r"\b[A-Za-z_][A-Za-z0-9_]*\b",
            },
        ]
    }

    repo["punctuation"] = {
        "patterns": [
            {"name": "punctuation.accessor.swoftlang", "match": r"\."},
            {"name": "punctuation.separator.swoftlang", "match": r"[,|]"},
            {
                "name": "punctuation.section.block.swoftlang",
                "match": r"[{}\[\]()]",
            },
        ]
    }

    # ---- top-level pattern order -------------------------------------------
    grammar = {
        "$schema": "https://raw.githubusercontent.com/martinring/tmlanguage/master/tmlanguage.json",
        "name": "swoftlang",
        "scopeName": "source.swoftlang",
        "fileTypes": ["sw"],
        "patterns": [
            {"include": "#comments"},
            {"include": "#strings"},
            {"include": "#builtins"},
            {"include": "#handlers"},
            {"include": "#namespaces"},
            {"include": "#namespace-accessor"},
            {"include": "#declarations"},
            {"include": "#receivers"},
            {"include": "#import"},
            {"include": "#storage-modifiers"},
            *([{"include": "#annotations"}] if annotations else []),
            {"include": "#property-accessor"},
            *([{"include": "#persistence-keywords"}] if persist_keywords else []),
            {"include": "#enums"},
            {"include": "#property-keys"},
            {"include": "#types"},
            {"include": "#user-types"},
            {"include": "#operator-words"},
            {"include": "#keywords"},
            *([{"include": "#ai-keywords"}] if ai_keywords else []),
            *([{"include": "#collection-ops"}] if collection_ops else []),
            {"include": "#constants"},
            {"include": "#numbers"},
            {"include": "#operators"},
            {"include": "#function-calls"},
            {"include": "#variables"},
            {"include": "#punctuation"},
        ],
        "repository": repo,
    }

    text = json.dumps(grammar, indent=2, ensure_ascii=False) + "\n"

    # ---- coverage assertion: every dump symbol must appear literally --------
    missing = []

    def check(items):
        for it in items:
            if it not in text:
                missing.append(it)

    check(sym["keywords"])
    check(ai_keywords)
    check(persist_keywords)
    check(collection_ops)
    check(sym["declarations"])
    check(receivers)
    check(sym["handlers"])
    check(sym["builtins"])
    check(sym["types"])
    check(sym["namespaces"])
    check(annotations)
    check(prop_names)
    for group, values in sym["enums"].items():
        check(values)
    if missing:
        print("MISSING FROM GRAMMAR:", sorted(set(missing)), file=sys.stderr)
        sys.exit(1)

    for path in (OUT_DOCS, OUT_EXT):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(text)

    # validate + identity
    with open(OUT_DOCS, "rb") as a, open(OUT_EXT, "rb") as b:
        da, db = a.read(), b.read()
    assert da == db, "grammar copies are not byte-identical"
    json.loads(da)

    npat = len(grammar["patterns"])
    print(f"wrote {len(da)} bytes to both grammars ({npat} top-level includes, "
          f"{len(repo)} repository rules); all dump symbols present; JSON valid; "
          f"byte-identical.")


if __name__ == "__main__":
    main()
