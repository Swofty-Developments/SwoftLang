#include "SwoftLangJNIBridge.h"
#include "SwoftLangParser.h"

jstring SwoftLangJNIBridge::parseSwoftLang(JNIEnv* env, jstring jcode) {
    // Convert Java string to C++ string
    const char* codeChars = env->GetStringUTFChars(jcode, NULL);
    std::string code(codeChars);
    env->ReleaseStringUTFChars(jcode, codeChars);
    
    try {
        // Parse the SwoftLang code
        std::vector<std::shared_ptr<Command>> commands = SwoftLangParser::parseCommands(code);
        
        // Convert to JSON
        std::string json = SwoftLangParser::commandsToJson(commands);
        
        // Return the JSON as a Java string
        return env->NewStringUTF(json.c_str());
    } catch (const std::exception& e) {
        // If there was an error, return an error message
        std::string errorMsg = "{\"error\": \"" + std::string(e.what()) + "\"}";
        return env->NewStringUTF(errorMsg.c_str());
    }
}

jobjectArray SwoftLangJNIBridge::parseSwoftLangToCommands(JNIEnv* env, jstring jcode) {
    // Convert Java string to C++ string
    const char* codeChars = env->GetStringUTFChars(jcode, NULL);
    std::string code(codeChars);
    env->ReleaseStringUTFChars(jcode, codeChars);
    
    try {
        // Parse the SwoftLang code
        std::vector<std::shared_ptr<Command>> commands = SwoftLangParser::parseCommands(code);
        
        // Find Command class in the correct package
        jclass commandClass = env->FindClass("net/swofty/nativebridge/representation/Command");
        if (commandClass == NULL) {
            return NULL; // Class not found
        }
        
        // Create an array of Command objects
        jobjectArray result = env->NewObjectArray(commands.size(), commandClass, NULL);
        
        // Fill the array with Command objects
        for (size_t i = 0; i < commands.size(); i++) {
            jobject jcommand = createJavaCommand(env, commands[i]);
            env->SetObjectArrayElement(result, i, jcommand);
            env->DeleteLocalRef(jcommand);
        }
        
        return result;
    } catch (const std::exception& e) {
        // If there was an error, throw a Java exception
        jclass exceptionClass = env->FindClass("java/lang/RuntimeException");
        env->ThrowNew(exceptionClass, e.what());
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaCommand(JNIEnv* env, const std::shared_ptr<Command>& command) {
    // Find Command class
    jclass commandClass = env->FindClass("net/swofty/nativebridge/representation/Command");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(commandClass, "<init>", "(Ljava/lang/String;)V");
    
    // Create Command object
    jstring jname = env->NewStringUTF(command->getName().c_str());
    jobject jcommand = env->NewObject(commandClass, constructor, jname);
    env->DeleteLocalRef(jname);
    
    // Set permission
    jmethodID setPermission = env->GetMethodID(commandClass, "setPermission", "(Ljava/lang/String;)V");
    jstring jpermission = env->NewStringUTF(command->getPermission().c_str());
    env->CallVoidMethod(jcommand, setPermission, jpermission);
    env->DeleteLocalRef(jpermission);
    
    // Set description
    jmethodID setDescription = env->GetMethodID(commandClass, "setDescription", "(Ljava/lang/String;)V");
    jstring jdescription = env->NewStringUTF(command->getDescription().c_str());
    env->CallVoidMethod(jcommand, setDescription, jdescription);
    env->DeleteLocalRef(jdescription);
    
    // Add arguments
    jmethodID addArgument = env->GetMethodID(commandClass, "addArgument", "(Lnet/swofty/nativebridge/representation/Variable;)V");
    for (const auto& arg : command->getArguments()) {
        jobject jarg = createJavaVariable(env, arg);
        env->CallVoidMethod(jcommand, addArgument, jarg);
        env->DeleteLocalRef(jarg);
    }
    
    // Add code blocks
    jmethodID addBlock = env->GetMethodID(commandClass, "addBlock", "(Ljava/lang/String;Ljava/lang/String;)V");
    for (const auto& [type, block] : command->getBlocks()) {
        jstring jtype = env->NewStringUTF(type.c_str());
        jstring jcode = env->NewStringUTF(block->getCode().c_str());
        env->CallVoidMethod(jcommand, addBlock, jtype, jcode);
        env->DeleteLocalRef(jtype);
        env->DeleteLocalRef(jcode);
    }
    
    return jcommand;
}

jobject SwoftLangJNIBridge::createJavaVariable(JNIEnv* env, const std::shared_ptr<Variable>& variable) {
    // Find Variable class
    jclass variableClass = env->FindClass("net/swofty/nativebridge/representation/Variable");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(variableClass, "<init>", "(Ljava/lang/String;Lnet/swofty/nativebridge/representation/DataType;)V");
    
    // Create DataType object
    jobject jdataType = createJavaDataType(env, variable->getType());
    
    // Create Variable object
    jstring jname = env->NewStringUTF(variable->getName().c_str());
    jobject jvariable = env->NewObject(variableClass, constructor, jname, jdataType);
    env->DeleteLocalRef(jname);
    env->DeleteLocalRef(jdataType);
    
    // Set default value if present
    if (variable->getHasDefault()) {
        jmethodID setDefault = env->GetMethodID(variableClass, "setDefault", "(Ljava/lang/String;)V");
        jstring jdefault = env->NewStringUTF(variable->getDefaultValue().c_str());
        env->CallVoidMethod(jvariable, setDefault, jdefault);
        env->DeleteLocalRef(jdefault);
    }
    
    return jvariable;
}

jobject SwoftLangJNIBridge::createJavaDataType(JNIEnv* env, const std::shared_ptr<DataType>& dataType) {
    // Find DataType class
    jclass dataTypeClass = env->FindClass("net/swofty/nativebridge/representation/DataType");
    
    // Find BaseType enum
    jclass baseTypeClass = env->FindClass("net/swofty/nativebridge/representation/BaseType");
    
    // Find static valueOf method for enum
    jmethodID valueOfMethod = env->GetStaticMethodID(baseTypeClass, "valueOf", "(Ljava/lang/String;)Lnet/swofty/nativebridge/representation/BaseType;");
    
    // Convert C++ enum to Java enum
    const char* typeName;
    switch (dataType->getBaseType()) {
        case BaseType::STRING: typeName = "STRING"; break;
        case BaseType::INTEGER: typeName = "INTEGER"; break;
        case BaseType::DOUBLE: typeName = "DOUBLE"; break;
        case BaseType::BOOLEAN: typeName = "BOOLEAN"; break;
        case BaseType::PLAYER: typeName = "PLAYER"; break;
        case BaseType::LOCATION: typeName = "LOCATION"; break;
        case BaseType::EITHER: typeName = "EITHER"; break;
        default: typeName = "UNKNOWN"; break;
    }
    
    jstring jtypeName = env->NewStringUTF(typeName);
    jobject baseType = env->CallStaticObjectMethod(baseTypeClass, valueOfMethod, jtypeName);
    env->DeleteLocalRef(jtypeName);
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(dataTypeClass, "<init>", "(Lnet/swofty/nativebridge/representation/BaseType;)V");
    
    // Create DataType object
    jobject jdataType = env->NewObject(dataTypeClass, constructor, baseType);
    env->DeleteLocalRef(baseType);
    
    // Add subtypes if it's an EITHER type
    if (dataType->getBaseType() == BaseType::EITHER) {
        jmethodID addSubType = env->GetMethodID(dataTypeClass, "addSubType", "(Lnet/swofty/nativebridge/representation/DataType;)V");
        
        for (const auto& subType : dataType->getSubTypes()) {
            jobject jsubType = createJavaDataType(env, subType);
            env->CallVoidMethod(jdataType, addSubType, jsubType);
            env->DeleteLocalRef(jsubType);
        }
    }
    
    return jdataType;
}

jobject SwoftLangJNIBridge::createJavaCodeBlock(JNIEnv* env, const std::shared_ptr<CodeBlock>& codeBlock) {
    // Find CodeBlock class
    jclass codeBlockClass = env->FindClass("net/swofty/nativebridge/representation/CodeBlock");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(codeBlockClass, "<init>", "(Ljava/lang/String;Ljava/lang/String;)V");
    
    // Create CodeBlock object
    jstring jtype = env->NewStringUTF(codeBlock->getType().c_str());
    jstring jcode = env->NewStringUTF(codeBlock->getCode().c_str());
    jobject jcodeBlock = env->NewObject(codeBlockClass, constructor, jtype, jcode);
    env->DeleteLocalRef(jtype);
    env->DeleteLocalRef(jcode);
    
    return jcodeBlock;
}