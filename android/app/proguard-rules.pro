# Keep Pigeon generated models
-keep class com.linkpilot.app.pigeon.** { *; }

# Keep kotlinx.serialization models
-keepattributes *Annotation*,InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keepclassmembers class * {
    *** Companion;
}
-keepclasseswithmembers class * {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,allowobfuscation,allowshrinking class com.linkpilot.core.model.** { *; }
-keep,allowobfuscation,allowshrinking class com.linkpilot.platform.storage.** { *; }
