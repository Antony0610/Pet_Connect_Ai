# Tests

Test structure for PetConnect AI.

## Structure

```
test/
├── unit/          # Unit tests (repositories, use cases, utilities)
├── widget/        # Widget tests (component library, screens)
└── integration/   # Integration tests (full flows, E2E)
```

Tests are written with `flutter_test` and `mocktail` for mocking. Run with:

```bash
flutter test
```

Tests are implemented alongside each feature during its development phase.
