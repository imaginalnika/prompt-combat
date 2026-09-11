# Extraction notes

Preserved source: incremental JSON field watcher/parser; rate normalization; exact-substring filtering; brace-window and text-field parsing; sentence paging. Preserved/adapted mechanics: attack/defense evaluation separation, history-backed prompts, attack-pressure curve, failure-streak probability adjustment, HP resolution, and alternating turns.

The session, state container, callable judge interface, and generic HTTP adapter were separated/adapted for standalone use. UI backreferences and scene transitions were replaced by signals and data. Character-specific modifiers, special weapons, forced outcomes, encounter prompts, pose systems, cinematics, art, and sounds are not included.

This is not a byte-for-byte copy of an application's combat controller. It is a reusable extraction of its general evaluation mechanics, with explicit standalone boundaries and neutral example content.
