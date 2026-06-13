# Research: Radial Deployment Menu & Unit Info Panel

Date: 2025-09-21  
Feature: 002-implement-radial-menu  
Spec Source: `specs/002-implement-radial-menu/spec.md`

## Overview

All ambiguities in the spec were previously resolved. Research here documents design decisions, rationale, and considered alternatives to support Phase 1 design artifacts and future maintenance.

## Decisions

### 1. Radial Ring Capacity

- Decision: 12 unit icon slots per page (excluding pagination controls) arranged evenly (30° increments; skip angles if reserved for pagination controls if visually necessary).
- Rationale: Balances readability and interaction target size; keeps icons legible at 1080p; <=12 prevents tight clustering.
- Alternatives: 8 (too restrictive; early pagination) / 16 (crowding risk) / dynamic scale (adds complexity & performance churn).

### 2. Pagination Approach

- Decision: Explicit next/previous buttons (two wedge-like UI nodes) appearing only when >12 units.
- Rationale: Predictable, accessible, low cognitive overhead. Avoids implicit scroll wheel behavior.
- Alternatives: Scroll wheel cycling (excludes controller parity), radial morph animation (higher complexity), multiple concentric rings (visual clutter).

### 3. Input Abstraction & Focus Management

- Decision: Maintain an ordered array of visible unit entries; track `focus_index`; provide mapping helpers:
  - Angular input → nearest sector index via vector angle quantization.
  - Cyclic navigation (LB/RB or Left/Right) → +/- index with wrap.
- Rationale: Simplifies parity across mouse hover and controller directional input.
- Alternatives: Spatial physics queries or nearest-neighbor each frame (unnecessary overhead).

### 4. Edge Reposition Strategy

- Decision: Shift radial center inward along both axes to keep full ring on screen; maximum shift limited to half ring diameter.
- Rationale: Preserves circular layout; avoids partial cropping.
- Alternatives: Dynamic arc (partial circle) (degrades visual consistency), scale-down (affects readability).

### 5. Disabled (Unaffordable) Units Handling

- Decision: Always render all known unit types; apply grayscale shader + red cost; still hoverable to show details.
- Rationale: Communicates future potential; consistent layout reduces spatial re-learning.
- Alternatives: Omit entirely (loss of planning info), separate list (fragmented UX).

### 6. Placement Validation Order & Failure Priority

- Decision: On selection confirm: validate resources first, then tile occupancy/zone. Resource failure takes precedence in event emission if both invalid.
- Rationale: Spec directive; user feedback clarity (resources often dynamic driver).
- Alternatives: Inverse order (contradicts finalized spec decision).

### 7. Debounce Implementation

- Decision: Timestamp last successful placement; block additional placements <250 ms apart.
- Rationale: Simplicity; avoids multi-unit race placement blasts.
- Alternatives: Input buffering or per-icon timers (overkill).

### 8. Scene Boundary of Responsibility

- Decision: `radial_menu.tscn` handles layout, focus transitions, signal emissions for hover/select/cancel; `unit_info_panel.tscn` handles display binding only; higher-level placement logic stays in `tile_map.gd` initially, refactored to `deployment_controller.gd` only if script exceeds cohesion threshold (approx >250 LOC or >3 reasons to change).
- Rationale: Minimize premature abstraction while guarding against monolith growth.
- Alternatives: Immediate controller extraction (may be premature until complexity real).

### 9. Feedback Mechanisms

- Decision: Flashing outline via temporary modulate tween + existing UI feedback sound channel.
- Rationale: Lightweight, no new assets required, reversible.
- Alternatives: Text toasts (not in spec), particle bursts (asset scope increase).

### 10. Optional MCP / Gemini Integration

- Decision: Attempt programmatic asset generation (scenes) via Godot MCP if available; on failure: fallback to manual coaching with checklist verification.
- Rationale: Aligns with tooling optional principle; ensures progress even if automation absent.
- Alternatives: Hard require MCP (violates Constitution optional tooling principle).

### 11. Memory & Performance Guardrails

- Decision: Free/destroy radial + panel nodes fully on close; no pooling initially; measure re-instantiation cost later.
- Rationale: Simplicity; feature likely low-frequency (per placement decision) in deployment phase only.
- Alternatives: Node pooling (premature until profiling shows need).

### 12. Data Model Representation

- Decision: Lightweight data dictionaries or small resource-style structs for `UnitType` interface binding; no early inheritance tree.
- Rationale: Avoid premature class hierarchy; rely on existing unit metadata sources.
- Alternatives: Abstract base classes (complexity without immediate polymorphic need).

## Consolidated Rationale

Design stakes center on clarity, extensibility (future filters), and deterministic interactions. Chosen approaches minimize complexity while meeting parity, accessibility, and performance constraints.

## Open Risks (Monitored)

- Potential future expansion (filters, chaining placement) may justify controller extraction.
- Pagination wedge buttons could reduce available angular sectors; may require adaptive angular spacing if visual collision occurs.
- Multiplayer edge cases (simultaneous placement) not fully stress-tested yet; future integration tests may expand.

## Deferred (Not in Scope This Feature)

- Filter tabs / category segmentation.
- Chain placement mode (Shift modifier) hinted in spec notes.
- Visual previews (ghosted unit model before commit).
- Node pooling for UI performance micro-optimizations.

## Outcome

All design questions resolved; no NEEDS CLARIFICATION markers remain. Ready for Phase 1 artifact generation (completed in this /plan run).
