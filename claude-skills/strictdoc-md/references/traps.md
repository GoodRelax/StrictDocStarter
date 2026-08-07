# Traps, and what to do when StrictDoc surprises you

Loaded by the `strictdoc-md` skill. Read this when an export fails, and before
you ship anything containing math or a table.

Everything here was measured on strictdoc 0.27.1. **When the version differs,
run the canary in the skill's section 6 before you trust any of it.**

---

## 0. When you hit an error that this guide does not cover

**We measured everything in this guide on strictdoc 0.27.1.** A different version
behaves differently. The other project may also write things in an unusual way.
**When that happens, this guide is certain to be wrong.**

**When it goes wrong, you do exactly three things.**

1. **Work around it and move on.** Your goal is to write the specification, not to fix StrictDoc
2. **Add exactly one line to `strictdoc-quirks.tsv`**
3. **Move on to the next task**

**★ Never chase the cause on the spot.** If you dig in, you never finish the work you
came for. **Read the collected lines together later and use them as the material for
fixing this guide.** Do not fix them one at a time: clear them all at once when the
version goes up or when the lines pile up.

### 0.1 How to write the log

**Put `strictdoc-quirks.tsv` directly inside the specification folder.** It is tab
separated, 6 columns, one line per entry. **Only append. Never rewrite or delete a
line that is already there.** StrictDoc does not parse `.tsv`, so the file has no
effect at all on your documents (measured).

| Column | Contents |
|---|---|
| `date` | `YYYY-MM-DD` |
| `sd_version` | The output of `strictdoc --version` |
| `step` | What you were doing. `export-html` / `export-json` / `jq` / `server` / `edit` |
| `symptom` | **The first line of the error, as it stands.** Cut it if it runs long |
| `workaround` | How you worked around it. **In one line** |
| `where` | Which file, and where in it |

If the file does not exist yet, create it together with its header line.

```bash
printf 'date\tsd_version\tstep\tsymptom\tworkaround\twhere\n' > <specification folder>/strictdoc-quirks.tsv
```

Add one line. **Append with `>>`. A single `>` erases the log you already have.**

```bash
printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date +%F)" "0.27.1" "export-html" "error: string index out of range" "put a character after the closing dollar" "04-lower.md" >> <specification folder>/strictdoc-quirks.tsv
```

**Write it in ASCII English.** You do that so a machine can process it later, and
because the error that lands in `symptom` is English.

### 0.2 What to log and what not to log

| Log it | Do not log it |
|---|---|
| An error **that this guide does not list** | A trap that this guide lists (a trailing `$`, for one) |
| Behavior that **differs** from what this guide describes | Your own typo |
| A step that failed because the version differs | Something that never comes back once you fix it |

**When you cannot decide, write it down.** One line costs little, and the knowledge
you lose never comes back.

### 0.3 How to use the log you collected

**Read it only when you clear the whole log at once.** When the same `symptom` shows
up again and again, it is a trap that this guide should describe.

```bash
cut -f2,4 <specification folder>/strictdoc-quirks.tsv | sort | uniq -c | sort -rn
```

Sort the log by version and **you see what changed in which version.**

```bash
sort -t"$(printf '\t')" -k2,2 -k1,1 <specification folder>/strictdoc-quirks.tsv
```

---

---

### `traps.md` ★ The `$` trap - the export stops for no apparent reason

**When `$` becomes the last character of a paragraph or of a table cell, the HTML export stops.**

```text
error: string index out of range
```

**It prints neither a file name nor a line number.** This is a defect on the strictdoc 0.27.1 side
(`_math_inline_rule` in `markdown_to_html_fragment_writer.py` reads past the end of the string).

| How you write it | Result |
|---|---|
| `The time is $T$` (the paragraph ends with math) | **stops** |
| `The time is $T$ here.` | passes |
| `\| symbol \| $T$ \|` (the cell ends with math) | **stops** |
| `\| symbol \| $T$ s \|` | passes |
| `\| symbol \| $$T$$ \|` (the cell uses `$$`) | passes |
| `The cost is 100 $` (it ends with a bare `$`) | **stops** |
| `The cost is 100 \$` | passes |
| `` The cost is `100 $` `` (inside a code span) | passes |
| a `$$ ... $$` block at the end of a section | passes |

**Remember one thing - always put a character after the closing `$`.**
A sentence ends with a period, so you keep this rule naturally in prose. **The table cell is where you cannot.**

**One more. When one line carries two `$` characters, MathJax turns what sits between them into math.** Money is not the only case.

| What you write | What comes out |
|---|---|
| `The cost is $100 to $200` | MathJax turns "100 to " into math |
| `$HOME and $PATH` | MathJax turns "HOME and " into math |
| `The cost is $100 only` (one `$`) | It comes out as written |

**A space after the `$` does not stop it** (`$ 100 to $ 200` turns into math as well).
Escape it as `\$100`, or put it in a code span as `` `$100` ``. **The export does not stop.**

**`--formats=json` passes this trap straight through** (measured). The JSON comes out fine, so
**if you end your work after looking at the JSON alone, the build fails the moment a human builds the HTML.**

**So whenever you touch a figure, a formula or code, run both of these.**

```bash
strictdoc export <specification folder> --formats=json --output-dir <output dir>
strictdoc export <specification folder> --formats=html --output-dir <output dir>
```

Once the JSON exists, you can hunt the dangerous lines by machine before you build the HTML.
**Zero hits is normal.** The query sits in **example 17** of `queries.md` (G33 in the detailed version).

**Do not close a table cell with a lone `$`.** You have two ways out, and **you take the first one.**

| How you write it | HTML it produces | How it looks |
|---|---|---|
| `\| $T$ s \|` (add a unit or a word) | `<span class="math ...">` | **It fits inside the text. Use this one** |
| `\| $$T$$ \|` (make it a block) | `<div class="math ...">` | It becomes a line of its own inside the cell and centers itself |
