// SwoftLangJNIBridge.h
#pragma once
#include <jni.h>
#include "Command.h"
#include <vector>
#include <memory>

class SwoftLangJNIBridge {
public:
    // Parse SwoftLang code and return a JSON representation
    static jstring parseSwoftLang(JNIEnv* env, jstring jcode);
    
    // Parse SwoftLang code and return a Command array
    static jobjectArray parseSwoftLangToCommands(JNIEnv* env, jstring jcode);
    
private:
    // Helper methods to convert C++ objects to Java objects
    static jobject createJavaCommand(JNIEnv* env, const std::shared_ptr<Command>& command);
    static jobject createJavaVariable(JNIEnv* env, const std::shared_ptr<Variable>& variable);
    static jobject createJavaDataType(JNIEnv* env, const std::shared_ptr<DataType>& dataType);
    static jobject createJavaCodeBlock(JNIEnv* env, const std::shared_ptr<CodeBlock>& codeBlock);
};