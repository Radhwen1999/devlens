# DevLens

Smart network inspector for Flutter Desktop & Web. Hold mouse wheel, hover over any widget, see its data.

## Install

```yaml
dev_dependencies:
  devlens: ^1.0.0
```

## Setup

```dart
import 'package:devlens/devlens.dart';

void main() {
  DevLens.init();
  runApp(DevLensOverlay(child: MyApp()));
}
```

Add interceptor:

```dart
// Dio
dio.interceptors.add(DevLensDioInterceptor());

// HTTP
final client = DevLensHttpClient();
```

## Usage

1. Hold **mouse wheel button**
2. Hover over any widget
3. See network data with matched field highlighted

No wrapper widgets needed. DevLens automatically detects which API response contains the displayed data.

## Configuration

```dart
DevLensOverlay(
  enabled: kDebugMode,
  config: DevLensConfig(
    maxRequests: 200,
    theme: DevLensTheme.light, // or DevLensTheme() for dark
  ),
  child: MyApp(),
)
```

## Platforms

Desktop (macOS, Windows, Linux) and Web only.

## License

MIT