/// Base contract for data sources (remote APIs, local cache, etc.).
///
/// A data source is a thin adapter over one source of truth (e.g. Supabase,
/// local DB, secure storage). Repositories call data sources and map their
/// results (DTOs) to domain entities. Data sources throw [AppException]s when
/// operations fail; repositories catch those and map them to [Failure]s.
///
/// This is a marker interface for documentation; concrete data sources are
/// defined per feature.
abstract interface class DataSource {}

/// Remote data source — talks to a backend (Supabase, REST API, etc.).
abstract interface class RemoteDataSource implements DataSource {}

/// Local data source — talks to on-device storage (cache, DB, secure store).
abstract interface class LocalDataSource implements DataSource {}
