/// Base contract for all repositories in the domain layer.
///
/// Repositories define the *what* (data operations) without specifying the
/// *how* (data source details). Concrete implementations live in the data
/// layer and coordinate between local/remote data sources.
///
/// This is a marker interface for documentation; concrete repositories are
/// defined per feature.
library;

abstract interface class Repository {}
