#!/usr/bin/env python3
"""keymap — entry point.

The logic lives in the `keymap` package (history / redact / parse / aliases /
profile / content / cli) and the shared `tui` package. This file only puts the
repo's tools/ dir on sys.path — resolved through the installer's symlink — so
`import keymap` and `import tui` work whether run in-repo or as
~/.config/keymap.py, then hands off to the CLI.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # repo tools/

from keymap.cli import main  # noqa: E402

if __name__ == "__main__":
    main()
