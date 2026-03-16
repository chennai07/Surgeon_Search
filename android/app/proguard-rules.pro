# Flutter rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Razorpay rules
-keepclassmembers class com.razorpay.** { *; }
-keep class com.razorpay.** { *; }

# General R8/ProGuard optimizations
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes Signature
-keepattributes InnerClasses

# Fix for missing Play Store Core classes (R8 errors)
-dontwarn com.google.android.play.core.**
