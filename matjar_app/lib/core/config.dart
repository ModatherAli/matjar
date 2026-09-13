/// Central app configuration.
///
/// The backend base URL can be overridden at build/run time:
/// `flutter run --dart-define=API_BASE_URL=http://localhost:4000`
/// Defaults to the Android emulator alias for the host machine.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    "API_BASE_URL",
    defaultValue: "http://10.0.2.2:4000",
  );

  static const String apiPrefix = "$baseUrl/api/v1";

  /// Backend stores image paths like `/uploads/products/x.png`.
  static String imageUrl(String path) {
    if (path.startsWith("http")) {
      return path;
    }
    return "$baseUrl$path";
  }
}

