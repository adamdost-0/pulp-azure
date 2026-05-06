#!/usr/bin/env python3
"""CLI wrapper for the typed fixture generator package."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from pulp_harness.generate_deb_fixture import main

if __name__ == "__main__":
    raise SystemExit(main())
