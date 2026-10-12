# Project Memory Skills

Terms for the repository’s project-memory skills and the documents they maintain.

## Recap workflow

**Recap checkpoint**:
The latest commit whose changes have been fully represented in `docs/recap.md`. It may lag behind the repository `HEAD` while a large history range is being processed.
_Avoid_: current HEAD, latest commit (unless it has been processed)

**History batch**:
A bounded range of up to 100 consecutive commits, processed oldest-to-newest during one recap invocation. The recap checkpoint advances only through commits represented in the recap.
_Avoid_: page (unless referring to Git output pagination)
