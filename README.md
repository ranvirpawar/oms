# Lifenity Connect – Build Instructions

## 🔹 Production Build
- Entry point: `lib/main.dart`
- Flavor: `production`

## Run

```bash
flutter run --flavor beta -t lib/beta_main.dart
```

```bash
flutter run --flavor production -t lib/main.dart
```


```bash
flutter build apk --flavor production -t lib/main.dart --release
```

```bash
flutter build appbundle --flavor production -t lib/main.dart --release
```
## 🔹 Beta Build
Uses `lib/beta_main.dart` as entry point.

```bash
flutter build apk --flavor beta -t lib/beta_main.dart --release
```

## 🔹 Dev Build
Uses `lib/dev_main.dart` as entry point — distinct app id
(`com.lifenity_health.oms.dev`), icon and launcher label (`OMS Dev`), so it
can be installed side-by-side with beta/production.

```bash
flutter run --flavor dev -t lib/dev_main.dart
```

```bash
flutter build apk --flavor dev -t lib/dev_main.dart --release
```
