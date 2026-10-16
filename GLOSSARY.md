# Project Memory Skills

Terms for the repository’s project-memory skills and the documents they maintain.

## Recap workflow

**Recap checkpoint**:
The latest commit whose changes have been fully represented in `docs/recap.md`. It may lag behind the repository `HEAD` while a large history range is being processed.
_Avoid_: current HEAD, latest commit (unless it has been processed)

**History batch**:
A set of at most 100 commits reviewed oldest-to-newest during one recap invocation. If unrepresented history remains, the next invocation resumes at the oldest unrepresented commit. The recap checkpoint advances only through commits represented by the published batch.
_Avoid_: page (unless referring to Git output pagination)

## Skill evaluation

**Skill effectiveness**:
A skill's demonstrated improvement in task success, safety, and usability compared with completing the same task without that skill. Evaluate it with paired, fresh-context runs on matched tasks.
