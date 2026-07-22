/// Openpanel client configuration.
class OpenpanelOptions {
  /// API base URL. Defaults to `https://api.openpanel.dev`.
  final String? url;

  final String clientId;
  final String? clientSecret;

  /// When true, failures are printed with `debugPrint`.
  final bool verbose;

  /// Fraction of installs that emit events (`0.0`–`1.0`).
  final double tracingSampleRate;

  const OpenpanelOptions({
    this.url,
    required this.clientId,
    this.clientSecret,
    this.verbose = false,
    this.tracingSampleRate = 1.0,
  });
}
