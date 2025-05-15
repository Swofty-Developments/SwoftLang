// net_swofty_nativebridge_NativeParser.cpp
#include <jni.h>
#include "SwoftLangJNIBridge.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Class:     net_swofty_nativebridge_NativeParser
 * Method:    parseSwoftLang
 * Signature: (Ljava/lang/String;)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_net_swofty_nativebridge_NativeParser_parseSwoftLang
  (JNIEnv *env, jclass cls, jstring code) {
    return SwoftLangJNIBridge::parseSwoftLang(env, code);
}

/*
 * Class:     net_swofty_nativebridge_NativeParser
 * Method:    parseSwoftLangToCommands
 * Signature: (Ljava/lang/String;)[Lnet/swofty/nativebridge/representation/Command;
 */
JNIEXPORT jobjectArray JNICALL Java_net_swofty_nativebridge_NativeParser_parseSwoftLangToCommands
  (JNIEnv *env, jclass cls, jstring code) {
    return SwoftLangJNIBridge::parseSwoftLangToCommands(env, code);
}

/*
 * Class:     net_swofty_nativebridge_NativeParser
 * Method:    parseSwoftLangToEvents
 * Signature: (Ljava/lang/String;)[Lnet/swofty/nativebridge/representation/Event;
 */
JNIEXPORT jobjectArray JNICALL Java_net_swofty_nativebridge_NativeParser_parseSwoftLangToEvents
  (JNIEnv* env, jclass clazz, jstring jcode) {
    return SwoftLangJNIBridge::parseSwoftLangToEvents(env, jcode);
}

#ifdef __cplusplus
}
#endif