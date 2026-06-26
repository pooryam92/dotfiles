#!/usr/bin/env python3
"""cheat — entry point.

The logic lives in the `cheat` package (data / content / cli) and the shared
`tui` package. This file only puts the repo's tools/ dir on sys.path — resolved
through the installer's symlink, the same trick data.py uses to find its TSVs —
so `import cheat` and `import tui` work whether run in-repo or as
~/.config/cheat.py, then hands off to the CLI.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))  # repo tools/

from cheat.cli import main  # noqa: E402

if __name__ == "__main__":
    main()
