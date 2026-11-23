# Flutter & Plugin Proguard Rules for AGARAM
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-dontwarn io.flutter.**
-dontwarn com.google.android.**
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
