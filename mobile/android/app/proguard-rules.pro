# Reglas de R8/ProGuard para el release de QuickBite.
#
# Flutter y sus plugins (connectivity_plus, image_picker, flutter_secure_storage…)
# se_channel de MethodChannel, que R8 no puede ver por reflexión: sin estas
# reglas el release arranca y se rompe al primer uso de un plugin.

# Canal de plataforma de Flutter.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Los plugins de la comunidad se registran por nombre de clase en el
# GeneratedPluginRegistrant, así que sus clases de implementación no se pueden
# eliminar sin romper el arranque.
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Serialización de modelos.
-keep class quickbite_mobile.**JsonSerializable { *; }
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
