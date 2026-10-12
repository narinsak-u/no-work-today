# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- `GLOSSARY.md` at the repo root, or `GLOSSARY-MAP.md` if it exists; read the glossary relevant to the task.
- `docs/adr/` for decisions that touch the area being changed.

If these files do not exist, proceed silently. Do not flag their absence or suggest creating them upfront. The domain-modeling skill creates them lazily when terms or decisions are resolved.

## File structure

This is a single-context repository: one root `GLOSSARY.md` and `docs/adr/` for architecture decisions.

## Use the glossary's vocabulary

Use terms as defined in `GLOSSARY.md`, including its stated avoided synonyms. If a needed concept is missing, reconsider the terminology or note the gap for domain modeling.

## Flag ADR conflicts

If work contradicts an existing ADR, surface the conflict explicitly rather than silently overriding it.
