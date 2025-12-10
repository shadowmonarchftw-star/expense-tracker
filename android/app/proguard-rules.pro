# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.client.** { *; }

# Google Sign In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.signin.** { *; }

# Prevent warnings
-dontwarn com.google.errorprone.annotations.**
