#!/bin/sh
echo -ne '\033c\033]0;Ballistic\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Ballistic.x86_64" "$@"
