#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd)

source_file="$repo_root/askllm"
target_file="$HOME/.local/bin/askllm"
dry_run=0

show_help() {
  cat <<'EOF'
Usage: install-askllm.sh [options]

Install the askllm Python wrapper into a user-local bin path.

Options:
  -s, --source PATH   Source askllm script path (default: repo_root/askllm)
  -t, --target PATH   Install path (default: ~/.local/bin/askllm)
      --dry-run       Show actions without writing files
  -h, --help          Show this help message
EOF
}

expand_home_path() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -s|--source)
      if [ "$#" -lt 2 ]; then
        echo "Error: $1 requires a value" >&2
        exit 2
      fi
      source_file="$2"
      shift 2
      ;;
    -t|--target)
      if [ "$#" -lt 2 ]; then
        echo "Error: $1 requires a value" >&2
        exit 2
      fi
      target_file="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      show_help >&2
      exit 2
      ;;
  esac
done

source_file=$(expand_home_path "$source_file")
target_file=$(expand_home_path "$target_file")

if [ ! -f "$source_file" ]; then
  echo "Error: source script not found: $source_file" >&2
  exit 1
fi

if [ "$dry_run" -eq 1 ]; then
  echo "[dry-run] mkdir -p $(dirname -- "$target_file")"
  echo "[dry-run] cp $source_file $target_file"
  echo "[dry-run] chmod +x $target_file"
  exit 0
fi

mkdir -p "$(dirname -- "$target_file")"
cp "$source_file" "$target_file"
chmod +x "$target_file"

echo "Installed askllm to $target_file"
