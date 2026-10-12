#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
[[ -d "$root" ]] || { printf 'Not a directory: %s\n' "$root" >&2; exit 1; }
root="$(cd "$root" && pwd)"
find "$root" \( -type d \( -name .git -o -name .worktrees -o -name node_modules -o -name dist -o -name build -o -name target -o -name vendor -o -name .next -o -name coverage -o -name .cache -o -name .venv -o -name venv -o -name generated \) -prune \) -o -type f \( -name package.json -o -name Cargo.toml -o -name go.mod -o -name pyproject.toml -o -name requirements.txt \) -print | while IFS= read -r manifest; do
  relative="${manifest#"$root"/}"
  case "${manifest##*/}" in
    package.json)
      printf '%s|JavaScript / TypeScript\n' "$relative"
      # Parse only immediate entries of root dependency maps; strings and nested
      # metadata can mention framework names without declaring a dependency.
      awk '
        function string_value() {
          if (state[depth] == "key" && type[depth] == "{") {
            key[depth] = text
            state[depth] = "colon"
          } else if (state[depth] == "value") {
            if (depth == dependency_depth) found[key[depth]] = 1
            values[depth]++
            state[depth] = "comma"
          } else invalid = 1
        }
        {
          for (i = 1; i <= length($0) + 1; i++) {
            c = i <= length($0) ? substr($0, i, 1) : " "
            if (quoted) {
              if (escaped) { escaped = 0; continue }
              if (c == "\\") { escaped = 1; continue }
              if (c == "\"") { quoted = 0; string_value(); continue }
              if (capture && length(text) < 128) text = text c
              continue
            }
            if (scalar) {
              if (c ~ /[[:space:],}\]]/) {
                if (word !~ /^(true|false|null|-?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?)$/) invalid = 1
                scalar = 0
                values[depth]++
                state[depth] = "comma"
              } else { word = word c; continue }
            }
            if (c ~ /[[:space:]]/) continue
            if (c == "\"") {
              if (!depth || (state[depth] != "key" && state[depth] != "value")) invalid = 1
              capture = depth && state[depth] == "key" && type[depth] == "{"
              text = ""
              quoted = 1
            } else if (c == "{" || c == "[") {
              if (depth && state[depth] != "value") invalid = 1
              if (!depth && (started || c != "{")) invalid = 1
              if (depth == 1 && c == "{" && (key[1] == "dependencies" || key[1] == "devDependencies" || key[1] == "peerDependencies" || key[1] == "optionalDependencies")) dependency_depth = 2
              if (depth) { state[depth] = "comma"; values[depth]++ }
              started = 1
              depth++
              type[depth] = c
              state[depth] = c == "{" ? "key" : "value"
              values[depth] = 0
            } else if (c == "}" || c == "]") {
              if (!depth || (c == "}" && type[depth] != "{") || (c == "]" && type[depth] != "[") || state[depth] == "colon" || ((state[depth] == "key" || state[depth] == "value") && values[depth])) invalid = 1
              if (depth == dependency_depth) dependency_depth = 0
              if (depth) depth--
            } else if (c == ":") {
              if (!depth || state[depth] != "colon") invalid = 1
              state[depth] = "value"
            } else if (c == ",") {
              if (!depth || state[depth] != "comma") invalid = 1
              state[depth] = type[depth] == "{" ? "key" : "value"
            } else if (c ~ /[-[:alnum:]]/) {
              if (!depth || state[depth] != "value") invalid = 1
              word = c
              scalar = 1
            } else invalid = 1
          }
        }
        END {
          if (invalid || depth || !started || quoted || scalar) exit
          count = split("next react remix vue nuxt svelte @sveltejs/kit hono express @nestjs/core", keys, " ")
          split("Next.js React Remix Vue Nuxt Svelte SvelteKit Hono Express NestJS", names, " ")
          for (j = 1; j <= count; j++) if (found[keys[j]]) print names[j]
        }
      ' "$manifest" | while IFS= read -r name; do printf '%s|%s\n' "$relative" "$name"; done
      ;;
    Cargo.toml)
      printf '%s|Rust\n' "$relative"
      awk '
        /^\[/ {
          section = ($0 ~ /^\[(dependencies|dev-dependencies|build-dependencies)\][[:space:]]*(#.*)?$/ || $0 ~ /^\[target\..*\.dependencies\][[:space:]]*(#.*)?$/)
          table = ($0 ~ /^\[(dependencies|dev-dependencies|build-dependencies)\.axum\][[:space:]]*(#.*)?$/ || $0 ~ /^\[target\..*\.dependencies\.axum\][[:space:]]*(#.*)?$/)
        }
        section && /^[[:space:]]*axum[[:space:]]*=/ { declared = 1 }
        table { declared = 1 }
        END { if (declared) print "Axum" }
      ' "$manifest" | while IFS= read -r name; do printf '%s|%s\n' "$relative" "$name"; done
      ;;
    go.mod) printf '%s|Go\n' "$relative" ;;
    pyproject.toml)
      printf '%s|Python\n' "$relative"
      awk '
        # A TOML comment and a bracket inside a quoted requirement are not
        # dependency syntax (for example fastapi[all]).
        function declaration_line(raw,    i, c, quote, escaped) {
          closed = 0
          for (i = 1; i <= length(raw); i++) {
            c = substr(raw, i, 1)
            if (escaped) { escaped = 0; continue }
            if (quote == "\"" && c == "\\") { escaped = 1; continue }
            if (quote) { if (c == quote) quote = ""; continue }
            if (c == "\"" || c == "\047") quote = c
            else if (c == "#") return substr(raw, 1, i - 1)
            else if (c == "]") closed = 1
          }
          return raw
        }
        {
          line = declaration_line($0)
          if (line ~ /^\[/) { section = line; array = 0 }
          if (section == "[project]" && line ~ /^[[:space:]]*dependencies[[:space:]]*=[[:space:]]*\[/) array = 1
          if (section == "[project.optional-dependencies]" && line ~ /^[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*=[[:space:]]*\[/) array = 1
          if (array) {
            if (tolower(line) ~ /["\047]fastapi([[:space:]<>=!~\[]|["\047])/) declared = 1
            if (closed) array = 0
          }
          if (section ~ /^\[tool\.poetry\.(group\.[^.]+\.)?dependencies\]/ && line ~ /^[[:space:]]*fastapi[[:space:]]*=/) declared = 1
        }
        END { if (declared) print "FastAPI" }
      ' "$manifest" | while IFS= read -r name; do printf '%s|%s\n' "$relative" "$name"; done
      ;;
    requirements.txt)
      printf '%s|Python\n' "$relative"
      if LC_ALL=C grep -Eiq '^[[:space:]]*fastapi([[:space:]<>=!~;\[]|$)' "$manifest"; then printf '%s|FastAPI\n' "$relative"; fi
      ;;
  esac
done | awk 'NR <= 120 { print } END { if (NR > 120) printf "... %d additional stack findings omitted; inspect a specific workspace next\n", NR - 120 }'
