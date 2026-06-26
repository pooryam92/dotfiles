"""profile — crunch (ts, command) events + aliases into the structured profile.

This dict is the single source both faces (the TUI and the plain/JSON output)
consume. Everything in it is already secret-redacted (see redact.py).
"""

from collections import Counter, defaultdict
from datetime import datetime

from . import __version__
from .parse import _SUBCMD_TOOLS, clean_toks, parse
from .redact import redact


def build_profile(events, aliases, limit=15):
    progs = Counter()
    subs: dict[str, Counter] = defaultdict(Counter)
    lines = Counter()           # exact (redacted) command lines
    alias_used = Counter()
    # Only multi-token expansions are real keystroke-savers worth flagging as
    # "missed"; a bare `alias g=git` would match every git line and just be noise.
    alias_exp = {a: clean_toks(exp) for a, exp in aliases.items() if exp}
    alias_exp = {a: t for a, t in alias_exp.items() if len(t) >= 2}
    alias_missed = Counter()
    total = 0
    have_ts = False
    ts_min = ts_max = None

    for ts, cmd in events:
        cmd = redact(cmd)
        total += 1
        lines[cmd] += 1
        prog, sub = parse(cmd)
        if prog:
            progs[prog] += 1
            if prog in aliases:
                alias_used[prog] += 1
            if sub:
                subs[prog][sub] += 1
        # "you typed the long form an alias would have saved you": the command's
        # leading tokens (flags included) exactly match the alias's expansion.
        ctoks = clean_toks(cmd)
        for a, etoks in alias_exp.items():
            if prog != a and ctoks[:len(etoks)] == etoks:
                alias_missed[a] += 1
        if ts:
            have_ts = True
            ts_min = ts if ts_min is None else min(ts_min, ts)
            ts_max = ts if ts_max is None else max(ts_max, ts)

    # Repeated, long command lines = prime alias candidates (multi-run + verbose).
    candidates = [
        {"cmd": c, "count": n, "len": len(c)}
        for c, n in lines.most_common()
        if n >= 3 and len(c) >= 18 and parse(c)[0] not in aliases
    ][:limit]

    alias_rows = [
        {"name": a, "expansion": exp, "used": alias_used.get(a, 0),
         "missed": alias_missed.get(a, 0)}
        for a, exp in sorted(aliases.items())
    ]

    def fmt(ts):
        return datetime.fromtimestamp(ts).astimezone().strftime("%Y-%m-%d") if ts else None

    return {
        "meta": {
            "version": __version__,
            "total_commands": total,
            "distinct_programs": len(progs),
            "timestamps_available": have_ts,
            "since": fmt(ts_min),
            "until": fmt(ts_max),
            "note": "All command text is secret-redacted before it appears here.",
        },
        "top_commands": [{"program": p, "count": n} for p, n in progs.most_common(limit)],
        "subcommands": {
            p: [{"sub": s, "count": n} for s, n in subs[p].most_common(8)]
            for p, _ in progs.most_common()
            if p in _SUBCMD_TOOLS and subs[p]
        },
        "alias_candidates": candidates,
        "aliases": alias_rows,
    }
