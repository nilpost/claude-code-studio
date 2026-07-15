---
name: example-skill
description: A sample shared skill that ships with studio-core. Invoke it to confirm that skills distributed via the studio marketplace load in this environment, or copy it as a template for authoring your own shared skills.
---

# example-skill

You are running `example-skill`, a shared skill distributed through the
`claude-code-studio` marketplace. If you can read this, skills authored in the
studio are reaching this environment (local project or ephemeral cloud session).

## What this demonstrates

- One plugin (`studio-core`) can bundle many skills, and installing the plugin
  makes all of them available without per-project copying.
- The same file loads identically on a laptop and in a fresh cloud container,
  because it is distributed as a versioned plugin rather than living in a
  machine-specific `~/.claude/`.

## Using this as a template

1. Copy this directory to `plugins/studio-core/skills/<your-skill>/`.
2. Rewrite the frontmatter `description` — it is what Claude matches on to decide
   when to invoke the skill, so make it specific and trigger-rich.
3. Put the instructions Claude should follow in the body. Add a `scripts/`
   subdirectory for any helper scripts and reference them with
   `${CLAUDE_PLUGIN_ROOT}`.
4. Push to the studio repo; run `claude plugin marketplace update
   claude-code-studio` (or start a fresh cloud session) everywhere else.
