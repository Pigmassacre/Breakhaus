#!/bin/bash
set -e
cd "$(dirname "$0")"
exec python3 upload_to_itchio.py "$@"
