# Claude Code skills

Skills that ship with StrictDocStarter. **This folder is the published copy.**
Claude Code does not read it directly - it reads `.claude/skills/`, which
`.gitignore` keeps out of the repository on purpose.

**A skill reaches this folder only after someone tested it end to end.**
`.claude/skills/` is the workbench: a skill under development lives there,
unpublished, until a real run against a real specification proves it works.
Copying an untested skill here publishes a promise nobody checked.

## Installing a skill

Copy the folder you want into your own `.claude/skills/`:

```bash
cp -r claude-skills/strictdoc-md ~/.claude/skills/
```

Per project instead of per user, copy it into the project's `.claude/skills/`.
Claude Code picks the skill up on the next session; `/strictdoc-md` then invokes
it by name, and the description makes it trigger on its own when the work fits.

## What is here

| Skill | What it does |
|---|---|
| `strictdoc-md` | Read, write, modify and audit Markdown StrictDoc specifications. Covers requirements, traceability, figures, math, code, tables and attachments, and carries an audit script for the four failures StrictDoc does not report. |

## Keeping the two copies together

**The copy in `.claude/skills/` and the copy here drift apart if you edit only
one.** Edit this one, then re-install:

```bash
cp -r claude-skills/strictdoc-md .claude/skills/
```

## strictdoc-md

Measured on **strictdoc 0.27.1, jq 1.8.1, Git Bash on Windows 11**. The skill
carries a canary that tells you whether its warnings still hold on a different
version.

```
strictdoc-md/
  SKILL.md              the rules, the preconditions and the four traps
  references/
    authoring.md        the .md shape, the rules that stop an export, a .sgra template
    notation.md         figures, math, code, tables, attachments
    traps.md            what breaks silently, and how to log a surprise
    queries.md          every jq query the guide teaches, with its measured output
  scripts/
    audit.sh            the four checks StrictDoc does not perform, plus a wording report
```

`samples/md-basic-en` is the worked example every query in the skill ran
against. `samples/md-basic-ja` is the same set in Japanese.
