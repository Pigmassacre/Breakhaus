#!/bin/bash
set -e
cd "$(dirname "$0")"
exec python3 build_game.py "$@"
