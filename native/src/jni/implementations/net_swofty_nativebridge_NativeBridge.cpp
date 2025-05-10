#include <jni.h>
#include <stdio.h>
#include "net_swofty_nativebridge_NativeBridge.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Class:     net_swofty_nativebridge_NativeBridge
 * Method:    printFromNative
 * Signature: (Ljava/lang/String;)V
 */
JNIEXPORT void JNICALL Java_net_swofty_nativebridge_NativeBridge_printFromNative
  (JNIEnv *env, jclass cls, jstring message) {
    // Convert jstring to C string
    const char *nativeString = env->GetStringUTFChars(message, 0);
    
    // Print the message
    printf("Native print: %s\n", nativeString);
    
    // Release the string
    env->ReleaseStringUTFChars(message, nativeString);
}

#ifdef __cplusplus
}
#endif