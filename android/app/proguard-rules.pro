# flutter_local_notifications uses Gson with anonymous TypeToken subclasses to
# serialise scheduled notifications into SharedPreferences. R8 strips generic
# signature attributes by default (Android Gradle Plugin 8+), which causes
# Gson 2.10+ to throw "Missing type parameter" when it tries to construct the
# TypeToken at runtime. The rules below preserve exactly what Gson needs.
-keepattributes Signature
-keepattributes EnclosingMethod

-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Keep the flutter_local_notifications plugin classes so R8 does not rename
# or strip the notification-receiver / serialisation code.
-keep class com.dexterous.** { *; }
