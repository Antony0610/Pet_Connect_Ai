# API Conventions

Conventions for talking to backends in **PetConnect AI**. The app is Clean Architecture, feature-first. All backend access flows through a **repository → datasource** boundary. Domain code never touches Supabase or Dio types directly.

- **Primary backend:** Supabase (`supabase_flutter`) — Auth, PostgreSQL + RLS, Storage, Realtime, Edge Functions.
- **Secondary transport:** `dio` — only for external REST services that are not fronted by Supabase.
- **Result type:** usecases and repositories return `Either<Failure, T>` (`dartz`).
- **Models:** `freezed` + `json_serializable` DTOs, mapped to plain domain entities.

---

## 1. Layering

```
presentation (Riverpod)  ->  domain (usecases, entities, repositories[abstract])
domain                   ->  data (repository impl, datasources, models)
data                     ->  Supabase / Dio
```

| Layer | Knows about | Never imports |
|-------|-------------|---------------|
| Domain | entities, `Failure`, abstract repos | Supabase, Dio, freezed models |
| Data (repo impl) | datasources, models, `Failure`, `Exception` | Riverpod, widgets |
| Data (datasource) | `SupabaseClient` / `Dio`, models, typed `Exception` | `Failure`, `Either` |
| Presentation | usecases, entities, `Either` | Supabase, Dio |

Rule of thumb: **datasources throw typed `Exception`s; repositories catch them and return `Failure`s.** `Either` and `Failure` never appear below the repository. Supabase/Dio types never appear above the datasource.

---

## 2. Datasource method naming

Methods are named for intent, not for the SQL verb. Suffix conventions:

| Suffix / prefix | Meaning | Returns |
|-----------------|---------|---------|
| `fetchX` / `fetchXList` | read single / list | model / `List<model>` |
| `watchX` | Realtime stream | `Stream<model>` |
| `createX` | insert | created model |
| `updateX` | partial update | updated model |
| `deleteX` | delete (soft where applicable) | `void` |
| `uploadX` / `downloadX` | Storage | path / bytes |
| `callX` | Edge Function invoke | model |

Datasources are split by responsibility: `XRemoteDataSource` (Supabase/Dio) and, where offline matters, `XLocalDataSource`.

```dart
abstract interface class PetRemoteDataSource {
  Future<List<PetModel>> fetchPetsForOwner(String ownerId, {int page = 0});
  Future<PetModel> fetchPetById(String id);
  Future<PetModel> createPet(PetModel pet);
  Future<PetModel> updatePet(String id, Map<String, dynamic> patch);
  Future<void> deletePet(String id);
  Stream<List<CollarTelemetryModel>> watchTelemetry(String collarId);
}
```

## 3. Supabase query conventions

Write queries with **RLS in mind**: the client never sends `owner_id`/`role` filters as a security measure — RLS enforces that server-side. Client filters exist only for correctness and performance.

**Select** — always name columns explicitly; avoid `select()` with no args. Use embedded resource syntax for joins.

```dart
final rows = await _client
    .from('pets')
    .select('id, name, species, breed, pet_media(url, is_primary)')
    .eq('owner_id', ownerId)          // correctness filter; RLS still enforces
    .order('created_at', ascending: false)
    .range(page * _pageSize, (page + 1) * _pageSize - 1);
```

**Insert** — insert only client-owned columns. Let DB defaults fill `id`, `created_at`. Chain `.select().single()` to get the created row back.

```dart
final row = await _client
    .from('pets')
    .insert({'name': pet.name, 'species': pet.species, 'owner_id': pet.ownerId})
    .select()
    .single();
```

**Update** — pass a partial patch map, never the whole entity. Scope with `.eq('id', id)`.

```dart
final row = await _client
    .from('pets').update(patch).eq('id', id).select().single();
```

**Delete** — prefer soft deletes (`deleted_at`) for user-facing records so audit and RAG stay intact; hard-delete only ephemeral rows.

Guidelines:
- Reads that expect exactly one row use `.single()`; zero-or-one use `.maybeSingle()`.
- Never build SQL strings. Use the query builder or RPC (`.rpc('fn', params:{...})`) for complex logic that lives in a Postgres function.
- Keep column selection tight — pulling `pet_media` for a list view but not for a picker.

## 4. Storage conventions

Buckets: `pet-media` (images/video), `pet-documents` (PDFs/scans), `ai-report-assets`. Object keys are namespaced by owner and pet so RLS storage policies can match on path prefix:

```
pet-media/{owner_id}/{pet_id}/{uuid}.jpg
pet-documents/{owner_id}/{pet_id}/{uuid}.pdf
```

```dart
final key = '${ownerId}/$petId/${_uuid.v4()}.jpg';
await _client.storage.from('pet-media').uploadBinary(key, bytes);
final publicUrl = _client.storage.from('pet-media').getPublicUrl(key);
```

Private buckets (documents) use `createSignedUrl(key, 3600)` instead of public URLs.

---

## 5. Realtime subscription conventions

Keep subscriptions scoped and short-lived. Subscribe when a widget mounts, unsubscribe on dispose. Never keep a global long-running subscription unless it's a system-wide concern (e.g., current user presence).

```dart
Stream<List<CollarTelemetryModel>> watchTelemetry(String collarId) {
  return _client
      .from('collar_telemetry')
      .stream(primaryKey: ['id'])
      .eq('collar_id', collarId)
      .order('timestamp', ascending: false)
      .limit(50)
      .map((rows) => rows.map((r) => CollarTelemetryModel.fromJson(r)).toList());
}
```

Use `.stream(primaryKey: [...])` rather than `.on()` for row-level change streams. Supabase Realtime respects RLS; the client sees only what RLS allows.

---

## 6. Error mapping (Exception → Failure)

Datasources throw typed `Exception`s; repositories catch them and wrap into `Failure`s. This keeps domain code Supabase-agnostic.

**Datasource layer** — throw typed exceptions:

```dart
class PetRemoteDataSourceImpl implements PetRemoteDataSource {
  final SupabaseClient _client;

  @override
  Future<PetModel> fetchPetById(String id) async {
    try {
      final row = await _client.from('pets').select().eq('id', id).maybeSingle();
      if (row == null) throw PetNotFoundException(id);
      return PetModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } on AuthException catch (e) {
      throw UnauthenticatedException(e.message);
    } on SocketException {
      throw NetworkException();
    }
  }
}
```

**Repository layer** — map to `Failure`:

```dart
class PetRepositoryImpl implements PetRepository {
  final PetRemoteDataSource _remote;

  @override
  Future<Either<Failure, Pet>> getPetById(String id) async {
    try {
      final model = await _remote.fetchPetById(id);
      return Right(model.toEntity());
    } on PetNotFoundException {
      return const Left(NotFoundFailure('Pet not found'));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on UnauthenticatedException {
      return const Left(AuthFailure('Session expired'));
    }
  }
}
```

**Failure hierarchy** (domain):

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure { ... }
class NetworkFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
```

---

## 7. Pagination conventions

Use offset/limit for simple lists; use cursor-based (`.gt('created_at', lastSeen)`) for infinite scroll where items may be inserted during pagination.

```dart
static const _pageSize = 20;

Future<List<PetModel>> fetchPetsForOwner(String ownerId, {int page = 0}) async {
  final rows = await _client
      .from('pets')
      .select()
      .eq('owner_id', ownerId)
      .order('created_at', ascending: false)
      .range(page * _pageSize, (page + 1) * _pageSize - 1);
  return rows.map((r) => PetModel.fromJson(r)).toList();
}
```

For cursor pagination:

```dart
Future<List<PostModel>> fetchPostsAfter(String? cursor, {int limit = 20}) async {
  var query = _client.from('community_posts').select().order('created_at', ascending: false).limit(limit);
  if (cursor != null) query = query.lt('created_at', cursor);
  final rows = await query;
  return rows.map((r) => PostModel.fromJson(r)).toList();
}
```

---

## 8. DTO (model) ↔ Entity mapping

DTOs (`freezed` + `json_serializable`) live in `data/models/`. Entities (plain Dart, sometimes `equatable`) live in `domain/entities/`.

**Model** (data layer):

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'pet_model.freezed.dart';
part 'pet_model.g.dart';

@freezed
class PetModel with _$PetModel {
  const factory PetModel({
    required String id,
    required String name,
    required String species,
    String? breed,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _PetModel;

  factory PetModel.fromJson(Map<String, dynamic> json) => _$PetModelFromJson(json);
}

extension PetModelX on PetModel {
  Pet toEntity() => Pet(
    id: id,
    name: name,
    species: species,
    breed: breed,
    ownerId: ownerId,
  );
}
```

**Entity** (domain layer):

```dart
class Pet extends Equatable {
  final String id;
  final String name;
  final String species;
  final String? breed;
  final String ownerId;

  const Pet({required this.id, required this.name, required this.species, this.breed, required this.ownerId});

  @override
  List<Object?> get props => [id, name, species, breed, ownerId];
}
```

Entities are timestamp-free and focused on business rules. Models carry server metadata (`created_at`, `updated_at`) but domain usecases never care about those.

---

## 9. When to use `dio` vs Supabase

| Use case | Tool | Why |
|----------|------|-----|
| Postgres CRUD, Auth, Storage, Realtime, Edge Functions | `supabase_flutter` | Primary backend, RLS enforced |
| External REST API (payment gateways, third-party AI, weather APIs) | `dio` | Not fronted by Supabase |
| Gemini API (RAG inference) | `dio` | Direct Google API call |
| n8n webhook triggers | `dio` | External automation |

Example `dio` setup for external API:

```dart
class GeminiRemoteDataSource {
  final Dio _dio;

  GeminiRemoteDataSource(this._dio) {
    _dio.options.baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  Future<String> generateText(String prompt, String apiKey) async {
    try {
      final response = await _dio.post(
        '/models/gemini-pro:generateContent',
        queryParameters: {'key': apiKey},
        data: {'contents': [{'parts': [{'text': prompt}]}]},
      );
      return response.data['candidates'][0]['content']['parts'][0]['text'];
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Gemini API error', code: e.response?.statusCode.toString());
    }
  }
}
```

---

## 10. Retry, timeout, offline handling

Use `connectivity_plus` to check network state before expensive operations. Set timeouts on all Supabase/Dio calls.

**Connectivity check**:

```dart
class NetworkInfo {
  final Connectivity _connectivity;
  NetworkInfo(this._connectivity);

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map((r) => r != ConnectivityResult.none);
}
```

**Repository with offline guard**:

```dart
@override
Future<Either<Failure, Pet>> getPetById(String id) async {
  if (!await _networkInfo.isConnected) {
    return const Left(NetworkFailure('No internet connection'));
  }
  // ... proceed with remote call
}
```

**Timeouts** — set at client level:

```dart
final supabase = SupabaseClient(url, anonKey, httpClient: http.Client()..timeout = const Duration(seconds: 30));
```

For Dio:

```dart
_dio.options.connectTimeout = const Duration(seconds: 10);
_dio.options.receiveTimeout = const Duration(seconds: 30);
```

**Retry logic** (for idempotent reads):

```dart
Future<T> _withRetry<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
  int attempt = 0;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      attempt++;
      if (attempt >= maxAttempts || e is! NetworkException) rethrow;
      await Future.delayed(Duration(seconds: attempt));
    }
  }
}
```

---

## 11. Request/response logging

Use `logger` package. Configure in main:

```dart
final logger = Logger(printer: PrettyPrinter(methodCount: 0));
```

Inject into datasources:

```dart
class PetRemoteDataSourceImpl {
  final SupabaseClient _client;
  final Logger _logger;

  @override
  Future<PetModel> fetchPetById(String id) async {
    _logger.d('Fetching pet: $id');
    try {
      final row = await _client.from('pets').select().eq('id', id).maybeSingle();
      _logger.i('Pet fetched: ${row?['name']}');
      if (row == null) throw PetNotFoundException(id);
      return PetModel.fromJson(row);
    } catch (e) {
      _logger.e('Failed to fetch pet $id', error: e);
      rethrow;
    }
  }
}
```

For Dio, use an interceptor:

```dart
_dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    _logger.d('→ ${options.method} ${options.uri}');
    return handler.next(options);
  },
  onResponse: (response, handler) {
    _logger.i('← ${response.statusCode} ${response.requestOptions.uri}');
    return handler.next(response);
  },
  onError: (e, handler) {
    _logger.e('✗ ${e.requestOptions.uri}', error: e);
    return handler.next(e);
  },
));
```

**Never log sensitive data** (passwords, tokens, session keys) — redact in production.

---

## Summary

| Convention | Rule |
|------------|------|
| Layering | Domain knows nothing about Supabase/Dio; repositories mediate |
| Datasource naming | `fetchX`, `createX`, `updateX`, `deleteX`, `watchX`, `callX` |
| Supabase queries | Name columns, use RLS-aware filters, avoid raw SQL |
| Storage paths | Namespace by owner/pet: `{bucket}/{owner_id}/{pet_id}/{uuid}.ext` |
| Realtime | Use `.stream(primaryKey:)`, scope to widget lifecycle |
| Error flow | Datasource throws `Exception`, repository returns `Either<Failure, T>` |
| Pagination | Offset/limit for simple; cursor for infinite scroll |
| DTO ↔ Entity | Models in `data/models/`, entities in `domain/entities/`; extension methods for mapping |
| Dio vs Supabase | Supabase for app backend; Dio only for external REST |
| Offline | Check `connectivity_plus` before expensive ops; set timeouts; retry idempotent reads |
| Logging | Inject `Logger`, log at datasource; intercept Dio; redact secrets |

