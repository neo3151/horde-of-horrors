#!/bin/sh
echo -ne '\033c\033]0;Horde of Horrors\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Horde of Horrors.x86_64" "$@"
