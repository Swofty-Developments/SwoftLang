---
title: Control Flow
---

<StepHeader>
a <code>/grade</code> command with real branching, counted loops, a player loop, and a guard-clause exit.
</StepHeader>

## `if` / `else if` / `else`

```swoftlang
command "grade" {
    arguments {
        score: Integer
    }
    execute {
        if args.score >= 90 {
            send "gold tier" to sender
        } else if args.score >= 50 {
            send "silver tier" to sender
        } else {
            send "bronze tier" to sender
        }
    }
}
```

Conditions use the comparison operators `<`, `>`, `<=`, `>=`, equality `=` / `==` / `is`,
inequality `!=` / `is not`, and combine with `and` / `or` / `not` (symbols `&&` and `||`
work too). Parentheses group.

The compiler's flow analysis follows every branch: a variable assigned in only *some*
branches is `optional` afterwards, and `is a` / `exists` checks narrow types per-branch —
[Step 07](/guide/options) shows how far that goes.

## Loops

`loop N times` repeats; `as i` binds the counter (1 to N). `loop <list> as x` iterates a
list. Skript's implicit `loop-number` and `loop-player` become explicit binders:

<MappedCompare>
<MappedPair label="counted and player loops">
<template #skript>

```skript
command /countdown:
    trigger:
        loop 5 times:
            send "count %loop-number%" to player
        loop all players:
            send "hello %loop-player%" to loop-player
```

</template>
<template #swoftlang>

```swoftlang
command "countdown" {
    execute {
        loop 5 times as i {
            send "count ${i}" to sender
        }
        loop all players as p {
            send "hello ${p.name}" to p
        }
    }
}
```

</template>
<template #note>

Whatever name you pick after `as` is a normal variable inside the body — no more
remembering which `loop-value` you're inside when loops nest. The loop variable is
scoped to its loop: when the loop ends, any outer binding of the same name is restored.

</template>
</MappedPair>
</MappedCompare>

The count can be any integer expression — `loop args.amount * 2 times` — and list loops
can cap themselves with `loop first 5 of all_players() as p`.

## `while`

```swoftlang
command "decay" {
    execute {
        set fuel to 10
        while fuel > 0 {
            set fuel to fuel - 3
        }
        send "fuel spent, ended at ${fuel}" to sender
    }
}
```

The condition re-evaluates before each pass.

::: warning The runaway guard
Scripts run inside a live server, so an accidental `while true` must not freeze a tick
forever. The executor caps any single `while` loop at **100,000 iterations**; past that
it stops the loop and logs a warning to the server console. If you genuinely need an
open-ended loop, you want an [async task](/guide/async) with a `wait` in it — that parks
a background task instead of burning a tick thread.
:::

## Loop over players

`loop all players as p` runs the body once per online player:

```swoftlang
command "roll" {
    execute {
        loop all players as p {
            send "you rolled ${random(1, 100)}" to p
        }
    }
}
```

## `halt`

`halt` stops the current script run immediately. Its main job is the guard-clause early
exit:

```swoftlang
command "launch" {
    arguments {
        countdown: Integer
    }
    execute {
        if args.countdown > 60 {
            send "<red>too long - 60s max" to sender
            halt
        }
        send "launching in ${args.countdown}s" to sender
    }
}
```

`halt` unwinds through function calls too — a `halt` inside a function ends the whole
script run, not just the function (use [`return`](/guide/functions#return) for that).
Inside an async task, `halt` kills *that task only*
([details](/guide/async#halt-in-a-task)).

## Brace-free bodies

Anywhere the grammar takes a `{ ... }` body — `if`/`else`, loops, function bodies,
`execute`, `async` blocks, GUI handlers — you can write exactly one statement with no
braces:

```swoftlang
command "terse" {
    execute {
        set x to 7
        if x > 5 send "big" to sender
        else if x = 5 send "exact" to sender
        else halt

        loop 3 times as i send "i = ${i}" to sender
    }
}
```

An `else` after a brace-free `if` binds to the nearest `if`. Two carve-outs: scoreboard
`lines { }` and tablist `column { }` bodies keep requiring braces — their contents are a
restricted DSL, not ordinary statements.

Next: pulling repeated logic out into functions — including functions as values.
