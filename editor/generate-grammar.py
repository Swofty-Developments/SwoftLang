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
    # v1.8.0 futures: await/when-is-ready/any (all/of/spawn live in other
    # buckets); Future is a generic type container below.
    "await", "when", "ready", "any",
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
                "match": r"\b(event|args|state|player|mob|killer|victim|run|item|index|old_item|new_item|reason|click_type|hook_location|caught_item|caught_mob|packet)\b(?=\.|\b)",
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
            {"include": "#enums"},
            {"include": "#property-keys"},
            {"include": "#types"},
            {"include": "#operator-words"},
            {"include": "#keywords"},
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
