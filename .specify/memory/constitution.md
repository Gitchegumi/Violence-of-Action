<!--
Sync Impact Report
Previous Version: 2.2.1 → New Version: 2.3.0 (MINOR bump: new principle added for Godot file handling)
Modified Principles: None
Added Sections: Principle VI - Godot File Handling Protocol
Removed Sections: None
Templates Updated: 
  ✅ .specify/templates/plan-template.md (verified - Constitution Check will include new principle)
  ✅ .specify/templates/spec-template.md (verified - no Godot-specific references)  
  ✅ .specify/templates/tasks-template.md (verified - no changes needed)
  ✅ .specify/templates/agent-file-template.md (verified - no changes needed)
Runtime Docs Checked:
  ✅ README.md (mentions .tscn files but no conflicts with new principle)
  ✅ docs/quickstart.md (no Godot file references)
Pending Updates: None
Deferred TODOs: None
-->

# Violence of Action Constitution

## Core Principles

### I. Engine Version Discipline

All development targets Godot 4.4.1. Minor/patch engine upgrades MAY be adopted after a
recorded upgrade review (build + smoke tests + performance sanity) and explicit mention in
the change log. No work depends on unreleased (nightly) APIs in mainline. Experimental
engine features MUST be isolated behind a feature flag or separate scene for rapid rollback.
Rationale: Ensures determinism, reduces integration friction, and supports stable tooling.

### II. GUT Test-First (Non-Negotiable)

Every gameplay logic change (scripts with branching or state) REQUIRES a failing GUT test
before implementation. Unit tests cover isolated script methods; integration tests cover
scene interactions (signals, node tree changes). A PR without new or updated tests for logic
changes MUST NOT be merged. Flaky tests MUST be fixed or quarantined within 24h.
Rationale: Prevents regressions and encourages small, verifiable increments.

### III. Modular Scene & Script Architecture

Scenes MUST encapsulate a single responsibility (UI component, unit behavior, system
controller). God objects and sprawling monolithic scripts are prohibited. Shared logic
belongs in reusable scripts/autoload singletons ONLY when used by >=2 distinct systems.
Circular dependencies between scripts MUST be eliminated before merge. Node signal usage
MUST be explicit (named constants or clearly documented). Rationale: Maintains clarity and
facilitates test isolation.

### IV. Observability & Deterministic Debugging

Logging uses the centralized `logger.gd`; raw `print()` calls are forbidden outside tests.
Randomized behavior MUST accept an injected seed for deterministic replay. Each feature with
time-based or probabilistic logic MUST expose a lightweight debug toggle or seed override.
Performance: Maintain 60 FPS target on reference hardware; any frame stutter >16ms added by
new code MUST be justified. Rationale: Faster debugging, reproducibility, and performance
guardrails.

### V. Versioning, Tooling & Automation

Semantic Versioning applies to externally consumed data schemas, save formats, and CLI
integrations. Backward-incompatible changes MUST increment MAJOR and include migration
notes. Internal gameplay tuning does not trigger version bumps. Gemini CLI & MCP integrations
MUST remain optional: core gameplay never hard-depends on Gemini availability. All scripts
exposed to external tooling MUST keep stable entry points. Rationale: Predictable evolution
and safe external integration.

### VI. Godot File Handling Protocol

Agents MUST NOT directly edit .tscn (scene) or .tres (resource) files using text manipulation
tools. These binary-adjacent formats require Godot's native serialization to maintain
integrity and prevent corruption. When Godot MCP is unavailable, agents MUST provide
specific user instructions and await confirmation before proceeding. Scene modifications
SHOULD use Godot MCP commands or manual user guidance only. Script attachment to scenes,
node hierarchy changes, and resource property updates MUST follow this protocol.
Rationale: Prevents file corruption, maintains Godot's internal consistency, and ensures
changes are properly validated by the engine.

## Additional Constraints

Performance Targets:

- Frame Time: 60 FPS target; sustained drops >5 seconds below 55 FPS require an issue.
- Memory: Avoid unbounded growth; large asset loads must stream or pool.

Testing Targets:

- Unit+integration GUT tests for all new systems.
- Critical path (deployment, combat start) MUST have integration coverage.

Input & Platform:

- Mouse + keyboard + (future) controller parity; mouse hover events always supported where
pointer context matters.

Upgrade Policy:

- Engine upgrade PR template MUST include: version delta, change log link, known API diffs,
screenshots of smoke test scenes, test pass summary.

Tooling:

- Gemini CLI & Godot MCP usage is supplementary—tooling scripts MUST fail gracefully when
unavailable.

## Development Workflow

Branch Flow:

1. Feature request → spec (`/specs/###-feature-name/spec.md`).
2. Planning (`plan.md`) enforces Constitution Check gates.
3. Tasks generated → implementation with GUT TDD.
4. Merge requires: green tests, updated documentation (if public-facing change), no lint
warnings introduced.

Review Gates (Mandatory):

- Principle II: Is there a failing or updated GUT test proving the change?
- Principle III: Does the script/scene do only one thing? Any accidental God object?
- Principle IV: Any new logs using logger? Any raw print() to remove?
- Principle V: Any breaking data/schema change? If yes, version bump artifact present?
- Principle VI: Any .tscn/.tres files modified? If yes, were proper protocols followed?

Prohibited Without Justification:

- Large (>400 LOC) single scripts.
- Hidden global state (undeclared singletons or dynamic node tree lookups without doc).
- Silent catch-all exception suppression.

## Governance

Authority: This constitution supersedes ad hoc practices. Conflicts resolved by updating this
document via PR.

Amendments:

- Proposal PR MUST describe rationale, impact, and version bump classification.
- MAJOR: Principle removal/redefinition affecting workflow.
- MINOR: New principle/section or material expansion.
- PATCH: Clarifications or non-semantic wording fixes.

Compliance:

- Constitution Check sections in planning templates MUST cite any intentional deviations.
- Deviations require explicit TODO with resolution owner & target date.

Review Cadence:

- Quarterly (or after 3 consecutive MINOR bumps) governance review issues are opened.

Versioning Policy:

- Stored at footer with ratification + last amended dates (ISO 8601).
- Changelog for governance kept in PR history and commit messages.

Escalation:

- Blocking violations (test absence, monolithic script, unseeded randomness) MUST be fixed
before merge—no deferrals.

**Version**: 2.3.0 | **Ratified**: 2025-09-21 | **Last Amended**: 2025-09-22
