# gmic-lab

Working folder for G'MIC CLI image work.

```
in/       source images — never written to
proxy/    25% working copies, used only for iterating with filters that render too slow
out/      generated results
masks/    reusable greyscale masks
include/  community filter sources, 28 contributor files (reference only, not loaded)
```
**---------- Local-only working folders ----------**
**`in`,`proxy`,`out`,`masks` folders themselves are kept in the repo so the structure described in**
**the README is visible. Their contents stay on my machine and copies in iCloud.**

---

## Setup

```bash
brew install gmic          # 4.0.4, bottled for Apple Silicon
brew install imagemagick   # for proxies and quick inspection
gmic -version
```

### Do this before anything else

macOS uses zsh, and zsh treats `[1]` as a filename glob. Every G'MIC command
with selection syntax will fail:

```
zsh:1: no matches found: +ge[1]
```

Add this to `~/.zshrc` and restart the terminal:

```bash
alias gmic='noglob gmic'
```

`noglob` stops zsh expanding the argument, and G'MIC gets `[1]` intact.
Scripts with a `#!/bin/zsh` shebang are unaffected — this only bites
when typing or pasting into an interactive zsh prompt.

---

## VS Code workflow

The thing that makes this work is running one command at a time instead of
executing a whole file.

1. Command Palette, search **Terminal: Run Selected Text In Active Terminal**
2. Bind it to a key (I'd use `Cmd+Enter`)
3. Open any scratchpad file, select a command, press the key

That gives you a notebook feel with no extra tooling: commented commands in a
file you keep, executed selectively, output in the terminal below.

### See results without leaving the editor

Split the editor and open an `out/*.png` in the right pane. VS Code previews
images, and the preview updates when the file changes on disk. Run a command
on the left, watch the result refresh on the right.

---

## Bringing commands over from Krita

In Krita: `Filter ▸ Start G'MIC-Qt`, tune with live preview, press the
copy-command button. You get something like `fx_something 3,20,0,1`.

Paste it between the input and the output:

```bash
gmic proxy/photo.png fx_something 3,20,0,1 o out/result.png
```

Krita bundles G'MIC 3.7.4.1; your CLI is 4.0.4. Newer on the CLI side, which
is the safe direction — anything Krita offers will run.

---

## Get help info for fx_something commands

### Verbose command
```bash
gmic -v 2
```
Can take values from 0 to 5 or more. It indicates how deep it traces
the nested function calls inside the gmic stdlib.
Useful to know which CLI commands make up a given GUI filter ("fx_...")

Example:

```bash
gmic -v 3 "in/sophie original.png" fx_edges 0.015,12.5,1 o out/edges.png
```
You can also look inside gmic_stdlib.gmic and ctrl+F the "fx_..." command
It's under the @GUI section, it gives you the help info and the code below

### How to pull this info programmatically directly in the terminal?

First download the G'MIC standard library
It has all the commands definitions for the CLI and GUI
```bash
curl -sL https://raw.githubusercontent.com/GreycLab/gmic/master/src/gmic_stdlib.gmic -o gmic_stdlib.gmic
```

Now grep it!
```bash
grep -C 10 "^fx_edges *:" gmic_stdlib.gmic 
```
`-C 10` — prints 10 lines above and below the match

`^fx_edges *:` — is aregular expression. The quotes stop the shell from expanding * as a glob.

`^` — anchor to start of line. Without it you'd also match lines where fx_edges appears mid-line, like calls to it inside other commands.

`fx_edges` — literal text.

` *` — a space followed by *. In regex, * means "zero or more of the preceding item," and the preceding item is the space character. So this matches any amount of whitespace-as-spaces, including none. So it matches `fx_edges:` and `fx_edges :` and `fx_edges   :`

`:` — literal colon.

---

## Community filters — reading `include/`

`include/` holds the 28 contributor files from the gmic-community repo.
15,245 filter declarations between them, roughly double the core stdlib.

You do **not** need to load these. Since G'MIC 3.4.0 the community set is
compiled into the binary, so on 4.0.4 they already work. The folder is here
purely so you can read parameters, which are documented nowhere else.

### Get the collection
```bash
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/GreycLab/gmic-community.git ~/gmic_community
cd ~/gmic_community && git sparse-checkout set include
```
**MOVED THE INCLUDE FOLDER TO ROOT OF THIS DIRECTORY (gmic-lab)**

### Finding a filter

```bash
grep -HE "^#@gui [^:[:space:]][^:]*:" include/*.gmic | grep -i "glitch"
```
Output:
```
include/joan_rake.gmic:#@gui Faux-QAM Glitch: fx_qam_glitch, fx_qam_glitch_preview(0)
```

`-H` — print the filename even when grepping one file. Tells you which
contributor wrote it.

`[^:[:space:]]` — the first character after `#@gui ` must not be a colon or a
space. Without this you also match the parameter lines, which all start
`#@gui : `, and the output fills with junk.

`[^:]*:` — anything up to the first colon. That colon separates the menu name
from the command name.

### The menu name is not the command name

```
#@gui Faux-QAM Glitch: fx_qam_glitch, fx_qam_glitch_preview(0)
     └── menu name ──┘  └── command ─┘  └── preview, ignore ──┘
```

You type the middle one. The `(0)` on the preview is a zoom factor for the
plugin and is irrelevant from the CLI.

### Reading the parameters

Arguments are positional and undocumented outside these files. The lines
below the declaration are the only spec that exists:

```bash
awk '/^#@gui Faux-QAM Glitch/{f=1} f&&/^#@gui : /{print} f&&/^[a-zA-Z_]+ *:/{exit}' include/joan_rake.gmic
```

`{f=1}` — set a flag when the declaration line is seen.

`f&&/^#@gui : /` — while the flag is set, print parameter lines.

`f&&/^[a-zA-Z_]+ *:/{exit}` — stop at the next command definition, so you get
one filter's block instead of the rest of the file.

Output:

```
#@gui : note = note("Tries to emulate the effect of a faulty Quadrature Amplitude Modulator.")
#@gui : sep = separator()
#@gui : note = note("<b>Channel Modulation</b>")
#@gui : 1. Amplitude = float(2,0,10)
#@gui : 2. Period = float(20,0,100)
#@gui : 3. Phase Offset = float(0,-180,180)
#@gui : 4. Angle = float(0,-180,180)
#@gui : 5. Amplitude Offset = float(1,-10,10)
...etc
```

Reading the typedefs:

```
float(default,min,max)     first number is the default
int(default,min,max)       same, integers
choice(...)                numbered from ZERO. choice(2,...) means default 2
bool(1)                    1 is on
point(x,y,...)             consumes TWO arguments, not one
separator()  note()  link()  consume NO argument — skip them when counting
```

Not every contributor numbers their parameters. When they don't, count the
argument-consuming lines yourself:

```bash
awk '/^#@gui Faux-QAM Glitch/{f=1} f&&/^#@gui : /{print} f&&/^[a-zA-Z_]+ *:/{exit}' \
  include/joan_rake.gmic | grep -cE "= *(float|int|choice|bool|color|point|text|value)\("
```

Remember to add one extra for every `point()`.

### Two things that will trip you up

**Most `fx_` filters declare no defaults.** They're written to be fed by a
dialog that always sends every value, so the bodies use bare `$7` rather than
`${7=default}`. The bare-comma trick does not work on them:

```
gmic in.png fx_qam_glitch ,
*** Error *** Command 'fx_qam_glitch': Undefined argument '$7'
```

Supply every argument, using the defaults you read out of the `#@gui` block.
This is the opposite of core commands like `edges`, which do declare defaults.

**Contributed filters can break across versions.** They're excluded from the
official reference on purpose, because they can change at any time. If you
build something you care about on one, either pin it or lift the technique
into your own command instead.

---

## Adding your own commands

G'MIC reads `~/.gmic` at startup, automatically, with no flags. It does not
create this file — you make it yourself. That is the whole install:

```bash
mv nimgwen.gmic ~/.gmic
gmic help nim_fm_glitch
```

`template.gmic` in this folder is the official scaffold from the community
repo. Copy its header block, keep `#@gmic` on line one, and delete its
explanatory preamble.

### File format

```
#@cli nim_thing : _amount,_mode={0|1}
#@cli : One-line description of what it does.
#@cli : Default values: 'amount=10' and 'mode=0'.
#@cli : $ image.jpg nim_thing 20,1

nim_thing : skip ${1=10},${2=0}
  blur $1%
  if $2 negate fi
```

A name followed by a colon starts a definition. Indented lines below it are
the body. Whitespace separates commands; commas separate arguments *within*
one command. `$1` is the first argument, substituted before the line runs.

`skip ${1=10}` declares defaults. Without them, calling with a missing
argument is a hard error.

`#@cli` blocks register help, so `gmic help nim_thing` works.

### Prefix your command names

The template is explicit about this, and with 15,245 community declarations in
circulation it matters — a collision fails silently and the loser just doesn't
exist. Everything here uses `nim_`.

### Folder placement for the GUI

Since `~/.gmic` is read by G'MIC-Qt as a local filter source, anything with
`#@gui` blocks shows up in Krita too. Convention is to keep new work under
`Testing / yourname` until it stabilises:

```
#@gui <b>Testing</b>
#@gui <i>nimgwen</i>
     ... your filters ...
#@gui __
```

`#@gui <b>Name</b>` enters a folder. `#@gui _` goes up one level, `#@gui __`
up two. The underscore is navigation, not part of the name.

Filters need a preview command as well to work in the plugin:

```
nim_thing_preview :
  gui_split_preview "nim_thing ${1-2}",${-3--1}
```

`${1-2}` passes arguments 1 through 2 to the real filter. `${-3--1}` passes
the last three — preview type plus the split point's x and y — to the
preview helper.

### Calling gotcha

Any command taking arguments swallows the next whitespace-separated token,
even when it's obviously another command:

```bash
gmic in.png nim_thing o out.png      # 'o' becomes argument 1
gmic in.png nim_thing , o out.png    # correct — bare comma means "no arguments"
```

You can skip positionally too: `nim_thing ,,3` passes only the third.

### While editing

Edit `~/.gmic` directly — `code ~/.gmic` — and changes take effect on the next
call. Or keep the canonical copy in this folder and load it explicitly while
iterating, which avoids clobbering the installed version:

```bash
gmic in.png -m nimgwen.gmic nim_thing 20,1 o out/test.png
```

G'MIC does **not** expand `~`. If you ever reference a path from inside a
command file, use the absolute form or the import fails silently.
