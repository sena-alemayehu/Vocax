/// An app on the phone that can be opened.
class InstalledApp {
  const InstalledApp({required this.name, required this.package});

  /// Name shown under the app icon, e.g. `YouTube`.
  final String name;

  /// Android package id, e.g. `com.google.android.youtube`.
  final String package;
}
