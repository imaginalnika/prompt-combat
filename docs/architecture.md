# Architecture

`combat_session.gd` is the public Node. Its phases are unconfigured, attack, damage evaluation, defense, rate evaluation, and finished. It owns a `combat_state.gd`, configurable `combat_rules.gd`, and child `eval_pipeline.gd`.

Attack text -> damage evaluation -> defense input -> success-rate evaluation -> authoritative RNG/HP resolution -> opposite participant's turn.

The pipeline accepts `judge(system, messages, kind) -> Dictionary`. It keeps separate histories by task kind. `damage` results require numeric `dmg`; `rate` requires numeric `success_rate`. Invalid or timed-out results return an explicit failure to the session, leaving that input retryable rather than inventing a successful judgment.

`evaluation_helpers.gd` provides normalization, substring filtering, brace-window parsing, field salvage, and sentence paging helpers. `json_stream_parser.gd` provides incremental string/number/array watchers and final JSON reconciliation. The default HTTP judge is nonstreaming; streaming hosts can use this parser independently through their judge adapter.

## Events and state

- `phase_changed(phase)` drives host input/UI.
- `defense_requested(attack)` requests the next input.
- `round_resolved(result)` carries original action/defense text, annotations, the real roll, effective rate, damage, and a state snapshot.
- `combat_finished(winner)` reports completion.
- `evaluation_failed(stage)` makes failed requests visible to the host.

Cancellation invalidates in-flight evaluations. Optional `generate_attack` / `generate_defense` use the same public input paths after model generation. No side can issue another action while evaluation is active.

## Probability policy

Attack pressure transforms probability with `p + pressure*p*(1-p)`. Optional failure-streak adjustment adds a configurable number of percentage points per miss. Exact 0% and 100% remain absolute. The returned `effective_rate` and `roll` are the actual resolution inputs.

The initial default is neutral (no pressure or failure bonus). Seed `rules.rng` for reproducible tests. Encounter-specific balancing belongs to the consuming application.
