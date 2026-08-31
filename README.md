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
