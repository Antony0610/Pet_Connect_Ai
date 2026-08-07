# Coding Standards

These are the conventions every contribution to PetConnect AI is expected to
follow. They exist to keep a large, four-portal Flutter codebase consistent,
reviewable, and safe to change. Where a rule is enforced by tooling, that is
noted; where it is a matter of judgment, the rationale is given.

---

## 1. Naming

### 1.1 Files and directories — `snake_case`
```
pet_repository_impl.dart
get_pets.dart
pet_owner_home_screen.dart
smart_collar/
```

Suffix files by their role so the layer is obvious from the filename:
`*_screen.dart`, `*_controller.dart`, `*_repository.dart` (abstract) /
`*_repository_impl.dart`, `*_datasource.dart`, `*_model.dart`. Use cases are
named for the action they perform (`book_appointment.dart`).

### 1.2 Classes — `PascalCase`
```dart
class PetRepositoryImpl implements PetRepository {}
class BookAppointment implements UseCase<Appointment, BookAppointmentParams> {}
class ServerFailure extends Failure {}
```

### 1.3 Members — `lowerCamelCase`
Variables, parameters, functions, and named constants all use
`lowerCamelCase`. Booleans read as predicates (`isLoading`, `hasCollar`,
`canEdit`).

### 1.4 Widgets
Widget class names are `PascalCase` and describe what they render, not how:
`PetCard`, `AppointmentTile`, `PrimaryButton`. Feature-local widgets live in the
feature's `presentation/widgets`; reusable design-system widgets live in
`shared/widgets`.

---

## 2. Immutability and `const`

- **Prefer `const`.** Any widget or value that can be `const` must be `const`.
  This is enforced by the linter (`prefer_const_constructors`,
  `prefer_const_literals_to_create_immutables`) and materially reduces rebuilds.
- **Model/entity immutability via freezed.** Entities and models are declared
  with `freezed`. Do not write mutable data classes by hand.

```dart
@freezed
class Pet with _$Pet {
  const factory Pet({
    required String id,
    required String name,
    required PetSpecies species,
    String? photoUrl,
  }) = _Pet;
}
```

- Fields are `final`. Mutations produce new instances via `copyWith`.

---

## 3. No Magic Numbers — Everything Comes From Tokens

**Never hardcode design values in a widget.** Colors, spacing, radii, elevation,
durations, and typography come from the design system in
`core/theme/tokens/*` and `core/theme/component_tokens/*`.

```dart
// Bad — magic numbers, off-system color
Padding(
  padding: const EdgeInsets.all(16),
  child: Container(color: const Color(0xFF6750A4)),
);

// Good — tokens
Padding(
  padding: EdgeInsets.all(context.tokens.spacing.md),
  child: Container(color: context.tokens.color.primary),
);
```

Non-design constants (keys, durations for logic, limits) belong in
`core/constants`, not inline. The rule is: **a bare numeric or color literal in a
widget is a code-review defect.**

---

## 4. Import Ordering

Group imports and separate groups with a blank line, in this order:

1. `dart:` imports
2. `package:` imports (Flutter, then third-party, alphabetized)
3. Project imports (`package:petconnect_ai/...`)

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/error/failures.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
```

Prefer `package:` absolute imports over long relative paths for cross-layer
imports. `directives_ordering` in the linter enforces the shape.

---

## 5. Folder Placement Rules

Decide where code lives with this checklist:

1. **Is it specific to one feature?** → that feature's `data`, `domain`, or
   `presentation` layer.
2. **Is it reused by multiple features?** → `shared/` (widget, entity, or model).
3. **Is it framework wiring (routing, theme, DI, errors, logging, network)?**
   → `core/`.
4. **Does it wrap an external system?** → app-wide clients (Supabase, Dio) live
   in `core/providers`; cross-cutting infrastructure wrappers (notifications,
   location, storage) live under `core/` and are injected via Riverpod; and
   feature-owned integrations (AI assistant, smart collar) live inside their
   feature module's `data/datasources`.

And respect the Dependency Rule (see `ARCHITECTURE.md`): `presentation` and
`data` may import `domain`; `domain` imports nothing outward; `presentation` and
`data` never import each other.

---

## 6. Widget-Local State and Disposable Controllers

The project uses **plain Riverpod** — `flutter_hooks`/`hooks_riverpod` are
intentionally **not** a dependency.

- Use a **`ConsumerStatefulWidget`** with `initState`/`dispose` for **ephemeral,
  widget-local UI state and disposable controllers** — text fields, animation
  controllers, focus nodes, scroll controllers. Dispose every controller you
  create.
- Use **Riverpod providers/controllers** for **shared or business-facing state**
  that outlives a single widget or is consumed in more than one place.

Rule of thumb: *if the state matters to the domain or is shared, it belongs in a
provider; if it is throwaway UI plumbing for one widget, keep it in the widget's
`State`.* See `STATE_MANAGEMENT.md`.

---

## 7. Lint Rules and Static Analysis

- Base ruleset: **`flutter_lints`**, extended with a **strict analyzer**
  configuration in `analysis_options.yaml`.
- `language.strict-casts`, `strict-inference`, and `strict-raw-types` are
  enabled — no implicit `dynamic`, no unchecked casts.
- Generated files (`*.freezed.dart`, `*.g.dart`) are excluded from analysis.
- **CI fails on any analyzer warning or lint.** Warnings are not allowed to
  accumulate. Run `flutter analyze` and `dart format` before pushing.

---

## 8. Documentation Comments

- Public classes, use cases, repositories, and non-obvious functions carry `///`
  dartdoc comments explaining **intent and contract**, not restating the code.
- Document the *why* for anything surprising, and document error behavior (what
  `Failure`s a use case can return).

```dart
/// Enables Lost Mode for [petId].
///
/// Switches the collar to high-frequency GPS reporting and broadcasts a
/// community alert. Returns [CollarUnreachableFailure] if the device cannot be
/// contacted over WiFi or BLE.
class EnableLostMode implements UseCase<void, EnableLostModeParams> { ... }
```

Avoid comments that narrate obvious code. Prefer clear names over comments.

---

## 9. Widget Size and the Extract-Widget Rule

- **Keep `build` methods readable.** As a guideline, if a widget's `build`
  exceeds ~100 lines or nests more than a few levels deep, extract sub-widgets.
- **Extract to a named widget, not a helper method.** Prefer a `const`
  `PascalCase` widget over a `Widget _buildX()` method — named widgets get their
  own rebuild boundary and are testable in isolation.
- One screen composes widgets; it does not inline a whole page of layout.

---

## 10. Error Handling Rules

- **Datasources throw typed Exceptions**; they never return `null` to signal
  failure and never construct `Failure`s.
- **Repositories catch Exceptions and return `Either<Failure, T>`** using the
  sealed `Failure` hierarchy in `core/error/failures.dart`.
- **Use cases return `Either<Failure, T>`** and do not throw for expected
  failures.
- **Controllers `fold` the `Either`** into `AsyncValue`/view state; the UI
  renders a state, it does not `try/catch` around business calls.
- Handle `Failure`s exhaustively — because they are sealed, `switch` is
  compiler-checked.

```dart
result.fold(
  (failure) => state = AsyncError(failure, StackTrace.current),
  (pets)    => state = AsyncData(pets),
);
```

---

## 11. No Business Logic in Widgets

Widgets **render state and emit intent** — nothing more.

- No network calls, no Supabase/Dio access, no data mapping, and no validation
  rules inside `build` or widget callbacks.
- A widget calls a controller method; the controller calls a use case; the use
  case owns the rule.
- Formatting for display (via `intl`) is fine in the presentation layer;
  decisions that affect data or domain state are not.

This keeps widgets thin, controllers orchestration-only, and business rules in
the framework-free `domain` layer where they can be unit-tested.

---

## 12. Quick Checklist for a Pull Request

- [ ] File names `snake_case`, classes `PascalCase`.
- [ ] `const` used everywhere possible; models/entities are freezed.
- [ ] No magic numbers or colors — values pulled from theme tokens.
- [ ] Imports grouped and ordered; project imports absolute.
- [ ] Code placed per the folder-placement + Dependency Rule.
- [ ] Errors flow Exception → `Failure` → `Either` → folded in controller.
- [ ] No business logic, I/O, or validation inside widgets.
- [ ] Public API documented; `flutter analyze` and `dart format` clean.
