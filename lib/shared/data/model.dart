import 'package:petconnect_ai/core/utils/typedefs.dart';

/// Marker interface for data-layer models (DTOs).
///
/// A model is the serializable representation of an [Entity]. Concrete models
/// are generated with `freezed` + `json_serializable` per feature; they:
/// - are created from JSON via a generated `fromJson`,
/// - serialize back via [toJson],
/// - and expose a `toEntity()` mapping to the domain object.
///
/// This interface documents the contract; feature models implement it.
abstract interface class Model {
  /// Serializes the model to a JSON map for the data source.
  Json toJson();
}
