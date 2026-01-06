/// DevLens - Smart network data inspection for Flutter
///
/// Zero-configuration widget inspection. Just initialize once in main()
/// and hold the mouse wheel button to inspect any widget's network data.
///
/// ```dart
/// void main() {
///   DevLens.init(); // That's it!
///   runApp(DevLensOverlay(child: MyApp()));
/// }
/// ```
library devlens;

export 'src/devlens.dart';
export 'src/devlens_overlay.dart';
export 'src/interceptors/devlens_dio_interceptor.dart';
export 'src/config/devlens_config.dart';