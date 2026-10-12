#!/usr/bin/env bash
set -euo pipefail

file="${1:-docs/backlog.md}"
[[ -s "$file" ]] || { printf 'Backlog missing or empty: %s\n' "$file" >&2; exit 1; }

# Validate the authoring contract without modifying the document. This cannot
# determine whether a candidate is meaningful or a completion claim is true.
LC_ALL=C awk '
  function error(message) { print "Backlog: " message " (line " NR ")" > "/dev/stderr"; bad = 1 }
  function finish_item(   field) {
    if (!item) return
    for (field in required) if (!seen_field[field]) error("item " item " missing " field)
    if (tasks == 0) error("item " item " has no checklist task")
    if (status != section) error("item " item " status does not match section " section)
    if (section == "Done") {
      if (completion != "Completed") error("Done item " item " lacks completed state")
      if (values["Completed on"] == "—" || values["Completion commit"] == "—" ||
          values["Completion evidence"] == "—" || values["Completion notes"] == "—")
        error("Done item " item " lacks completion record")
    } else if (completion != "Not completed") error("unfinished item " item " has completed state")
    for (field in seen_field) delete seen_field[field]
    for (field in values) delete values[field]
    item = ""
    tasks = 0
  }
  BEGIN {
    split("Status|Priority|Context|Tasks|Related|Files|Depends on|Blocked by|Completion|Completed on|Completion commit|Completion evidence|Completion notes", keys, /[|]/)
    for (i in keys) required[keys[i]] = 1
  }
  {
    sub(/\r$/, "")
    if ($0 == "# Project Backlog") { title++; next }
    if ($0 == "<!-- skill-state") { if (in_state || ++states > 1) error("duplicate skill-state"); in_state = 1; next }
    if (in_state) {
      if ($0 == "-->") { in_state = 0; next }
      if ($0 ~ /^output_sha256: /) {
        if ($0 !~ /^output_sha256: [0-9a-f]+$/ || length($0) != 79 || ++fingerprints > 1)
          error("invalid output_sha256")
        else digest = substr($0, 16)
      } else error("unexpected skill-state content")
      next
    }
    if ($0 ~ /^output_sha256: /) error("fingerprint outside skill-state")
    if ($0 ~ /^## /) {
      finish_item()
      section = substr($0, 4)
      if (section != "In Progress" && section != "Todo" && section != "Blocked" && section != "Needs Review" && section != "Done")
        error("unknown section " section)
      if (++sections[section] > 1) error("duplicate section " section)
      next
    }
    if ($0 ~ /^### /) {
      finish_item()
      if (!section) error("item outside status sections")
      split($0, title_parts, " ")
      item = title_parts[2]
      if (item !~ /^BL-[0-9][0-9][0-9][0-9]*$/ || $0 !~ /^### BL-[0-9][0-9][0-9][0-9]* — .+/)
        error("invalid item heading")
      if (++ids[item] > 1) error("duplicate ID " item)
      next
    }
    if ($0 == "- **Tasks:**" && item) {
      if (++seen_field["Tasks"] > 1) error("duplicate Tasks field")
      next
    }
    if ($0 ~ /^  - \[[ x]\] .+/ && item) { tasks++; next }
    if ($0 ~ /^ *- \*\*[^*]+:\*\* / && item) {
      label = $0
      sub(/^ *- \*\*/, "", label)
      sub(/:\*\*.*/, "", label)
      value = $0
      sub(/^ *- \*\*[^*]+:\*\* /, "", value)
      if (!required[label]) { error("unknown field " label); next }
      if (++seen_field[label] > 1 || value == "") error("duplicate or empty field " label)
      values[label] = value
      if (label == "Status") {
        status = value
        if (value != "Todo" && value != "In Progress" && value != "Blocked" && value != "Needs Review" && value != "Done") error("invalid status " value)
      }
      if (label == "Priority" && value != "High" && value != "Medium" && value != "Low") error("invalid priority " value)
      if (label == "Completion") completion = value
    }
  }
  END {
    finish_item()
    split("In Progress|Todo|Blocked|Needs Review|Done", headings, /[|]/)
    for (i in headings) if (sections[headings[i]] != 1) error("missing section " headings[i])
    if (title != 1) error("missing or duplicate title")
    if (in_state || states != 1 || fingerprints != 1) error("missing or invalid skill-state fingerprint")
    if (bad) exit 1
    print digest
  }
' "$file" >/dev/null || exit 1

# Remove only the fingerprint VALUE line contents, preserving its line ending
# (including CRLF), every other byte, and the surrounding comment delimiters.
expected="$(LC_ALL=C awk '/^output_sha256: / { sub(/\r$/, ""); print substr($0, 16) }' "$file")"
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(LC_ALL=C sed '/^output_sha256: /s/^output_sha256: [0-9a-f]\{64\}//' "$file" | sha256sum)"
  actual="${actual%% *}"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(LC_ALL=C sed '/^output_sha256: /s/^output_sha256: [0-9a-f]\{64\}//' "$file" | shasum -a 256)"
  actual="${actual%% *}"
elif command -v openssl >/dev/null 2>&1; then
  actual="$(LC_ALL=C sed '/^output_sha256: /s/^output_sha256: [0-9a-f]\{64\}//' "$file" | openssl dgst -sha256)"
  actual="${actual##* }"
else
  printf 'Backlog: SHA-256 utility unavailable (sha256sum, shasum, or openssl required)\n' >&2
  exit 1
fi
[[ "$actual" == "$expected" ]] || { printf 'Backlog fingerprint mismatch: %s\n' "$file" >&2; exit 1; }
