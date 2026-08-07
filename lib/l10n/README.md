# Localization (l10n)

This folder holds the app's translation source files (ARB) and is wired to
Flutter's built-in `gen-l10n` tooling via the root `l10n.yaml`.

## Status: prepared, not yet enabled

The scaffolding exists so translations can be added incrementally, but code
generation is intentionally **off** so it never blocks `flutter pub get` before
the team commits to shipping localized strings.

## Enabling localization

1. In `pubspec.yaml`, under `dependencies`, add:

   ```yaml
   flutter_localizations:
     sdk: flutter
   ```

2. In `pubspec.yaml`, under the `flutter:` section, add:

   ```yaml
   flutter:
     generate: true
   ```

3. Run `flutter pub get`. This generates `AppLocalizations` (import
   `package:flutter_gen/gen_l10n/app_localizations.dart`).

4. Wire the delegates into `MaterialApp.router` in `lib/app.dart`:

   ```dart
   localizationsDelegates: AppLocalizations.localizationsDelegates,
   supportedLocales: AppLocalizations.supportedLocales,
   ```

## Adding strings

- Add the key + English value to `app_en.arb` (the template) with an `@key`
  metadata block describing its usage.
- Mirror the key in every other locale file (`app_ar.arb`, …).
- Reference in widgets as `AppLocalizations.of(context).yourKey`.

## Conventions

- Namespaced keys: `common*`, `nav*`, `auth*`, `petOwner*`, `vet*`, etc.
- Never hard-code user-facing copy in widgets once l10n is enabled.
- `app_en.arb` is the source of truth; other locales are translations of it.
