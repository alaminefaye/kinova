class ApiConfig {
  ApiConfig._();

  /// Production KINOVA API
  static const String baseUrl = 'https://kinovaci.com/api';

  /// Origine du site (pour médias /storage/...)
  static const String origin = 'https://kinovaci.com';

  /// Transforme une URL média relative ou localhost en URL absolue prod.
  static String resolveMediaUrl(String? url) {
    if (url == null) return '';
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1') {
        return '$origin${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      }
      return trimmed;
    }

    if (trimmed.startsWith('/')) return '$origin$trimmed';
    return '$origin/$trimmed';
  }
}
