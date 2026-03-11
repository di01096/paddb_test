#!/bin/sh
set -e

# Run the python script to check, download, and slice new awakenings if available
echo "=> Checking for awakenings update..."
python slice_awakenings.py || echo "Warning: slice_awakenings.py failed, but continuing..."

# Start a simple HTTP server on port 80 to serve the PAD Card Guide
echo "=> Starting web server on port 80..."
exec python -m http.server 80
