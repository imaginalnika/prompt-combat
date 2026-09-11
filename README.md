# prompt-combat

A Godot framework for LLM-evaluated natural-language combat.

Participants describe attacks and defenses. A configurable judge estimates damage and success probability; deterministic game code resolves the roll, updates HP, and advances the turn. The model proposes and evaluates actions—it does not directly declare the authoritative outcome.

## Features

- Text-input attack/defense loop with optional generated actions.
- Separate damage and success evaluation, bounded history, and explicit failures.
- Exact-substring damage annotations and incremental structured-response parsing.
- Configurable attack pressure and failure-streak probability adjustment.
- Seedable RNG, neutral combatant data, cancellation, and presentation signals.

## Quick start

Tested with Godot 4.7.1. The example uses a deterministic mock judge; no account or network access is needed:

```sh
godot --headless --path . --script examples/demo.gd
python3 tools/verify.py
```

Copy `addons/prompt_combat` into a project. Add `combat_session.gd` as a Node, call `configure(first, second)` with distinct IDs and positive HP, and supply `pipeline.judge` as an async-compatible callable:

```gdscript
combat.pipeline.judge = your_judge
await combat.submit_attack("I make a quick feint.")
var resolution = await combat.submit_defense("I step aside.")
```

The judge receives `(system_prompt, messages, kind)` and returns a dictionary. `http_json_judge.gd` supplies an optional OpenAI-compatible chat endpoint adapter with explicit configuration. Voice input can submit transcribed text; no microphone library is required.

## Scope

An initial standalone extraction/adaptation of an existing combat implementation, with application-specific encounters and presentation removed. This does not claim that the original application imports the package. No original characters, story rules, artwork, audio, or cinematic assets are included.

The included neutral prompts demonstrate the schema; they are not balance guarantees or hardened protection against adversarial player instructions. Hosted-model compatibility and game balance need separate testing.

See [architecture](docs/architecture.md), [extraction notes](docs/provenance.md), and [security](SECURITY.md).

Apache-2.0; see [LICENSE](LICENSE) and [NOTICE](NOTICE). Godot is a separate MIT-licensed dependency.
