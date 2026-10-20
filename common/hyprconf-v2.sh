#!/usr/bin/env bash
# Hyprconf Quickshell delegation
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
exec "$dir/hyprconf.sh" "$@"
