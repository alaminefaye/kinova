# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Gson / JSON (si utilisé par des plugins)
-keepattributes Signature
-keepattributes *Annotation*

# Play Core (référencé par Flutter, optionnel pour apps sans dynamic delivery)
-dontwarn com.google.android.play.core.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
