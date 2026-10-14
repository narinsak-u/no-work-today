# Project Memory Skills

Terms for the repository’s project-memory skills and the documents they maintain.

## Recap workflow

**Recap checkpoint**:
The latest commit whose changes have been fully represented in `docs/recap.md`. It may lag behind the repository `HEAD` while a large history range is being processed.
_Avoid_: current HEAD, latest commit (unless it has been processed)

**History batch**:
A set of at most 100 commits reviewed oldest-to-newest during one recap invocation. If unrepresented history remains, the next invocation resumes at the oldest unrepresented commit. The recap checkpoint advances only through commits represented by the published batch.
_Avoid_: page (unless referring to Git output pagination)

<<<<<<< HEAD
<<<<<<< HEAD
## Skill evaluation

**Skill effectiveness**:
A skill's demonstrated improvement in task success, safety, and usability compared with completing the same task without that skill. Evaluate it with paired, fresh-context runs on matched tasks.
=======
=======
>>>>>>> d910d8d (feat: improve catchup overview inventories)
## Catchup overview
**Technology stack**:
The major languages/runtimes, frameworks, data stores, and queues evidenced as actively used by a repository. A declared or transitive dependency alone is not proof of active use.

**Application workflow**:
A verified end-to-end runtime path from trigger to outcome, including relevant checks and side effects. One endpoint or internal helper alone is not a workflow.
_Avoid_: flow (when referring to a documented application workflow)

**API endpoint**:
One explicitly registered HTTP method and route template; each distinct method-and-path pair counts as a separate endpoint, including different methods on the same path.
_Avoid_: URL (when counting endpoints; a URL alone omits the method)
<<<<<<< HEAD
>>>>>>> f398d16 (docs: add catchup overview glossary terms)
=======
>>>>>>> d910d8d (feat: improve catchup overview inventories)
