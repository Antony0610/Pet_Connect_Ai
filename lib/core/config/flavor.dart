/// Build flavors / runtime environments for PetConnect AI.
///
/// The active flavor is resolved at startup from the `APP_ENV` value in the
/// loaded `.env` file (see [Env]) and drives environment-specific config such
/// as which Supabase project and endpoints to talk to.
enum Flavor {
  dev,
  staging,
  prod;

  static Flavor fromName(String? name) => switch (name?.toLowerCase().trim()) {
        'prod' || 'production' => Flavor.prod,
        'staging' || 'stage' => Flavor.staging,
        _ => Flavor.dev,
      };

  bool get isDev => this == Flavor.dev;
  bool get isStaging => this == Flavor.staging;
  bool get isProd => this == Flavor.prod;

  /// Whether verbose logging / debug affordances should be enabled.
  bool get isDebuggable => this != Flavor.prod;
}
