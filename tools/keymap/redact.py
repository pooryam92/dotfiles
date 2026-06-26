"""redact — the privacy layer.

Every command line is run through `redact()` BEFORE it is counted, shown, or
emitted — so a stray `curl -H "authorization: Bearer …"` never reaches the
report, the JSON, or the agent. Isolated in its own module so it's easy to audit
and extend in one place.

Each pattern keeps any leading flag/key and masks only the secret value, so the
*shape* of the command survives (useful signal) while the secret does not.
"""

import re

_MASK = "‹redacted›"
_REDACTORS = [
    # --password=… / --token … / -p… and friends (value may follow = or space)
    (re.compile(r"(?i)(-{1,2}(?:password|passwd|pass|token|secret|api[-_]?key|"
                r"apikey|auth|access[-_]?token|bearer|key)[=\s]+)(\S+)"), r"\1" + _MASK),
    # FOO_TOKEN=… style env assignments with a secret-ish key
    (re.compile(r"(?i)\b([A-Z0-9_]*(?:KEY|TOKEN|SECRET|PASS|PWD|CREDENTIAL)[A-Z0-9_]*=)"
                r"(\S+)"), r"\1" + _MASK),
    # Authorization: Bearer <jwt-ish>
    (re.compile(r"(?i)(authorization:\s*bearer\s+)(\S+)"), r"\1" + _MASK),
    # URLs carrying user:pass@host
    (re.compile(r"(://[^/\s:@]+:)[^/\s@]+(@)"), r"\1" + _MASK + r"\2"),
    # Well-known token shapes (provider-prefixed)
    (re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{16,}|sk-[A-Za-z0-9]{16,}|"
                r"xox[baprs]-[A-Za-z0-9-]{8,}|AKIA[0-9A-Z]{16})\b"), _MASK),
    # JWTs: three base64url segments
    (re.compile(r"\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b"), _MASK),
    # Long high-entropy blobs (hex ≥32, or base64-ish ≥40) — catch-all, last.
    (re.compile(r"\b[A-Fa-f0-9]{32,}\b"), _MASK),
    (re.compile(r"\b[A-Za-z0-9+/]{40,}={0,2}\b"), _MASK),
]


def redact(cmd: str) -> str:
    for pat, repl in _REDACTORS:
        cmd = pat.sub(repl, cmd)
    return cmd
