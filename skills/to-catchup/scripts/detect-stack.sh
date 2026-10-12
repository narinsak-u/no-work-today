#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"
find "$root" \( -type d \( -name .git -o -name node_modules -o -name dist -o -name build -o -name target -o -name vendor -o -name .next -o -name coverage -o -name .cache \) -prune \) -o -type f \( -name package.json -o -name Cargo.toml -o -name go.mod -o -name pyproject.toml -o -name requirements.txt \) -print | while IFS= read -r manifest; do
  relative="${manifest#"$root"/}"
  case "${manifest##*/}" in
    package.json)
      printf '%s|JavaScript / TypeScript\n' "$relative"
      for framework in 'next:Next.js' 'react:React' 'remix:Remix' 'vue:Vue' 'nuxt:Nuxt' 'svelte: SvelteKit' 'hono:Hono' 'express:Express' '@nestjs/core:NestJS'; do
        key="${framework%%:*}"
        if grep -Eq '"'"$key"'"[[:space:]]*:' "$manifest"; then
          printf '%s|%s\n' "$relative" "${framework#*:}"
        fi
      done
      ;;
    Cargo.toml)
      printf '%s|Rust\n' "$relative"
      if grep -Eq '(^|[[:space:]])axum[[:space:]]*=' "$manifest"; then
        printf '%s|Axum\n' "$relative"
      fi
      ;;
    go.mod) printf '%s|Go\n' "$relative" ;;
    pyproject.toml|requirements.txt)
      printf '%s|Python\n' "$relative"
      if grep -iq 'fastapi' "$manifest"; then printf '%s|FastAPI\n' "$relative"; fi
      ;;
  esac
done
