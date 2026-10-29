# ML Kit text recognition references optional script recognizers (Chinese,
# Devanagari, Japanese, Korean) that this app does not bundle. R8 fails the
# release build on the missing references unless told to ignore them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit entry points R8 might otherwise strip.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
