# Keep Firebase and Google Play Services classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep all Flutter-related classes
-keep class io.flutter.** { *; }

# Prevent removing annotation-based reflection
-keepattributes *Annotation*

# Keep localization classes
-keep class * implements android.content.res.Resources$Theme { *; }





# Preserve log statements for debugging
-assumenosideeffects class android.util.Log { *; }