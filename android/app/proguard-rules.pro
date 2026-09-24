# R8 / ProGuard rules for the release build.
#
# Without this file the release build dies in `minifyReleaseWithR8`, because
# NewPipeExtractor references platform and optional classes that are not on the
# Android runtime — `javax.script`, `jdk.dynalink`, `java.beans`,
# `org.mozilla.javascript.tools` — and R8 full mode treats those as errors.
#
# The rule sets below are taken from SimpMusic, which ships the same
# dependencies (androidApp/proguard-rules.pro and
# service/kotlinYtmusicScraper/proguard-rules.pro in
# https://github.com/maxrave-dev/SimpMusic and https://github.com/maxrave-dev/core).
# Rules for libraries this app does not use (Retrofit, Room, Sentry, yt-dlp,
# Spotify) are deliberately left out.

# ---------------------------------------------------------------------------
# NewPipeExtractor — the native stream extractor
# ---------------------------------------------------------------------------
# timeago patterns are loaded reflectively by locale name, so they cannot be
# renamed or shrunk away.
-keep class org.schabi.newpipe.extractor.timeago.patterns.** { *; }
-keep class org.schabi.newpipe.extractor.** { *; }
-keep class org.mozilla.javascript.** { *; }
-keep class org.mozilla.classfile.ClassFileWriter
-dontwarn org.mozilla.javascript.tools.**
-keep class org.jsoup.** { *; }
-dontwarn java.beans.BeanDescriptor
-dontwarn java.beans.BeanInfo
-dontwarn java.beans.IntrospectionException
-dontwarn java.beans.Introspector
-dontwarn java.beans.PropertyDescriptor
-dontwarn javax.script.AbstractScriptEngine
-dontwarn javax.script.Bindings
-dontwarn javax.script.Compilable
-dontwarn javax.script.CompiledScript
-dontwarn javax.script.Invocable
-dontwarn javax.script.ScriptContext
-dontwarn javax.script.ScriptEngine
-dontwarn javax.script.ScriptEngineFactory
-dontwarn javax.script.ScriptException
-dontwarn javax.script.SimpleBindings
-dontwarn jdk.dynalink.**
-dontwarn org.slf4j.impl.StaticLoggerBinder

# ---------------------------------------------------------------------------
# OkHttp — used by the extractor's downloader
# ---------------------------------------------------------------------------
-dontwarn okhttp3.internal.platform.**
-dontwarn okhttp3.internal.Util
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn org.codehaus.mojo.animal_sniffer.**
-dontwarn javax.annotation.**

# ---------------------------------------------------------------------------
# Coroutines
# ---------------------------------------------------------------------------
-keep class kotlinx.coroutines.CoroutineExceptionHandler
-keep class kotlinx.coroutines.internal.MainDispatcherFactory

# ---------------------------------------------------------------------------
# This app's own native bridge
# ---------------------------------------------------------------------------
# MainActivity answers the com.hifi.app/stream MethodChannel and is named in the
# manifest, so it must survive obfuscation by its fully qualified name.
-keep class com.hifi.app.** { *; }

# Keep line numbers so release crash reports stay readable.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
