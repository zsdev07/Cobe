# Cobe ProGuard rules
-keep class zx.offical.cobe.** { *; }
-keep class io.flutter.** { *; }
-keepclassmembers class * {
    native <methods>;
}
# Keep JNI/FFI symbols
-keepclasseswithmembernames class * {
    native <methods>;
}
