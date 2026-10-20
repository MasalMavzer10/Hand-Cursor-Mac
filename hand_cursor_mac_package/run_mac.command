#!/bin/bash
cd "$(dirname "$0")"
echo "========================================================="
echo " Local Hand + Head/Mouth Cursor for macOS (v2.0)"
echo "========================================================="
if [ ! -d ".venv" ]; then
  echo "Creating local Python virtual environment (.venv)..."
  python3 -m venv .venv
fi
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
echo "Launching hand_cursor_mac.py..."
python3 hand_cursor_mac.py
