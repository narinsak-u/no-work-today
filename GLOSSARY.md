# Project Memory Skills

Terms for the repository’s project-memory skills and the documents they maintain.

## Recap workflow

**Recap checkpoint**:
The latest commit whose changes have been fully represented in `docs/recap.md`. It may lag behind the repository `HEAD` while a large history range is being processed.
_Avoid_: current HEAD, latest commit (unless it has been processed)

**History batch**:
A bounded set of commits reviewed oldest-to-newest as part of one recap invocation. An invocation can review multiple history batches; it does not advance the recap checkpoint until the complete selected range is represented.
_Avoid_: page (unless referring to Git output pagination)
