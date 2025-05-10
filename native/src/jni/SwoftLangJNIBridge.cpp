#include "SwoftLangJNIBridge.h"
#include "SwoftLangParser.h"
#include <memory>
#include <ExecuteBlockParser.h>

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

jobject SwoftLangJNIBridge::parseExecuteBlock(JNIEnv* env, jstring jcode) {
    // Convert Java string to C++ string
    const char* codeChars = env->GetStringUTFChars(jcode, NULL);
    std::string code(codeChars);
    env->ReleaseStringUTFChars(jcode, codeChars);
    
    try {
        // Create lexer and tokenize
        Lexer lexer(code);
        std::vector<Token> tokens = lexer.tokenize();
        
        // Create execute block parser
        ExecuteBlockParser parser(tokens);
        auto executeBlock = parser.parseExecuteBlock();
        
        // Convert to Java object
        return createJavaExecuteBlock(env, executeBlock);
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
    
    // Set execute block if present
    if (command->getExecuteBlock()) {
        jmethodID setExecuteBlock = env->GetMethodID(commandClass, "setExecuteBlock", 
            "(Lnet/swofty/nativebridge/representation/ExecuteBlock;)V");
        jobject jexecuteBlock = createJavaExecuteBlock(env, command->getExecuteBlock());
        env->CallVoidMethod(jcommand, setExecuteBlock, jexecuteBlock);
        env->DeleteLocalRef(jexecuteBlock);
    }
    
    return jcommand;
}

jobject SwoftLangJNIBridge::createJavaExecuteBlock(JNIEnv* env, const std::shared_ptr<ExecuteBlock>& block) {
    // Find ExecuteBlock class
    jclass executeBlockClass = env->FindClass("net/swofty/nativebridge/representation/ExecuteBlock");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(executeBlockClass, "<init>", "()V");
    
    // Create ExecuteBlock object
    jobject jblock = env->NewObject(executeBlockClass, constructor);
    
    // Add statements
    jmethodID addStatement = env->GetMethodID(executeBlockClass, "addStatement", 
        "(Lnet/swofty/nativebridge/representation/Statement;)V");
        
    for (const auto& statement : block->getStatements()) {
        jobject jstatement = createJavaStatement(env, statement);
        env->CallVoidMethod(jblock, addStatement, jstatement);
        env->DeleteLocalRef(jstatement);
    }
    
    return jblock;
}

jobject SwoftLangJNIBridge::createJavaStatement(JNIEnv* env, const std::shared_ptr<Statement>& statement) {
    // Determine statement type and create appropriate Java object
    if (auto sendCmd = std::dynamic_pointer_cast<SendCommand>(statement)) {
        return createJavaSendCommand(env, sendCmd);
    } else if (auto teleportCmd = std::dynamic_pointer_cast<TeleportCommand>(statement)) {
        return createJavaTeleportCommand(env, teleportCmd);
    } else if (auto haltCmd = std::dynamic_pointer_cast<HaltCommand>(statement)) {
        return createJavaHaltCommand(env, haltCmd);
    } else if (auto ifStmt = std::dynamic_pointer_cast<IfStatement>(statement)) {
        return createJavaIfStatement(env, ifStmt);
    } else if (auto blockStmt = std::dynamic_pointer_cast<BlockStatement>(statement)) {
        return createJavaBlockStatement(env, blockStmt);
    } else if (auto varAssign = std::dynamic_pointer_cast<VariableAssignment>(statement)) {
        return createJavaVariableAssignment(env, varAssign);
    }
    
    // Unknown statement type
    throw std::runtime_error("Unknown statement type");
}

jobject SwoftLangJNIBridge::createJavaExpression(JNIEnv* env, const std::shared_ptr<Expression>& expression) {
    // Determine expression type and create appropriate Java object
    if (auto stringLit = std::dynamic_pointer_cast<StringLiteral>(expression)) {
        return createJavaStringLiteral(env, stringLit);
    } else if (auto varRef = std::dynamic_pointer_cast<VariableReference>(expression)) {
        return createJavaVariableReference(env, varRef);
    } else if (auto binExpr = std::dynamic_pointer_cast<BinaryExpression>(expression)) {
        return createJavaBinaryExpression(env, binExpr);
    } else if (auto typeLit = std::dynamic_pointer_cast<TypeLiteral>(expression)) {
        return createJavaTypeLiteral(env, typeLit);
    }
    
    // Unknown expression type
    throw std::runtime_error("Unknown expression type");
}

jobject SwoftLangJNIBridge::createJavaSendCommand(JNIEnv* env, const std::shared_ptr<SendCommand>& command) {
    // Find SendCommand class
    jclass sendClass = env->FindClass("net/swofty/nativebridge/representation/SendCommand");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(sendClass, "<init>", 
        "(Lnet/swofty/nativebridge/representation/Expression;Lnet/swofty/nativebridge/representation/Expression;)V");
    
    // Create expression objects
    jobject jmessage = createJavaExpression(env, command->getMessage());
    jobject jtarget = command->getTarget() ? createJavaExpression(env, command->getTarget()) : NULL;
    
    // Create SendCommand object
    jobject jsend = env->NewObject(sendClass, constructor, jmessage, jtarget);
    
    // Clean up local references
    env->DeleteLocalRef(jmessage);
    if (jtarget) env->DeleteLocalRef(jtarget);
    
    return jsend;
}

jobject SwoftLangJNIBridge::createJavaTeleportCommand(JNIEnv* env, const std::shared_ptr<TeleportCommand>& command) {
    // Find TeleportCommand class
    jclass teleportClass = env->FindClass("net/swofty/nativebridge/representation/TeleportCommand");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(teleportClass, "<init>", 
        "(Lnet/swofty/nativebridge/representation/Expression;Lnet/swofty/nativebridge/representation/Expression;)V");
    
    // Create expression objects
    jobject jentity = createJavaExpression(env, command->getEntity());
    jobject jtarget = createJavaExpression(env, command->getTarget());
    
    // Create TeleportCommand object
    jobject jteleport = env->NewObject(teleportClass, constructor, jentity, jtarget);
    
    // Clean up local references
    env->DeleteLocalRef(jentity);
    env->DeleteLocalRef(jtarget);
    
    return jteleport;
}

jobject SwoftLangJNIBridge::createJavaHaltCommand(JNIEnv* env, const std::shared_ptr<HaltCommand>& command) {
    // Find HaltCommand class
    jclass haltClass = env->FindClass("net/swofty/nativebridge/representation/HaltCommand");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(haltClass, "<init>", "()V");
    
    // Create HaltCommand object
    return env->NewObject(haltClass, constructor);
}

jobject SwoftLangJNIBridge::createJavaIfStatement(JNIEnv* env, const std::shared_ptr<IfStatement>& statement) {
    // Find IfStatement class
    jclass ifClass = env->FindClass("net/swofty/nativebridge/representation/IfStatement");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(ifClass, "<init>", 
        "(Lnet/swofty/nativebridge/representation/Expression;Lnet/swofty/nativebridge/representation/Statement;Lnet/swofty/nativebridge/representation/Statement;)V");
    
    // Create objects
    jobject jcondition = createJavaExpression(env, statement->getCondition());
    jobject jthen = createJavaStatement(env, statement->getThenStatement());
    jobject jelse = statement->getElseStatement() ? createJavaStatement(env, statement->getElseStatement()) : NULL;
    
    // Create IfStatement object
    jobject jif = env->NewObject(ifClass, constructor, jcondition, jthen, jelse);
    
    // Clean up local references
    env->DeleteLocalRef(jcondition);
    env->DeleteLocalRef(jthen);
    if (jelse) env->DeleteLocalRef(jelse);
    
    return jif;
}

jobject SwoftLangJNIBridge::createJavaBlockStatement(JNIEnv* env, const std::shared_ptr<BlockStatement>& statement) {
    // Find BlockStatement class
    jclass blockClass = env->FindClass("net/swofty/nativebridge/representation/BlockStatement");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(blockClass, "<init>", "()V");
    
    // Create BlockStatement object
    jobject jblock = env->NewObject(blockClass, constructor);
    
    // Add statements
    jmethodID addStatement = env->GetMethodID(blockClass, "addStatement", 
        "(Lnet/swofty/nativebridge/representation/Statement;)V");
    
    for (const auto& stmt : statement->getStatements()) {
        jobject jstatement = createJavaStatement(env, stmt);
        env->CallVoidMethod(jblock, addStatement, jstatement);
        env->DeleteLocalRef(jstatement);
    }
    
    return jblock;
}

jobject SwoftLangJNIBridge::createJavaVariableAssignment(JNIEnv* env, const std::shared_ptr<VariableAssignment>& assignment) {
    // Find VariableAssignment class
    jclass assignClass = env->FindClass("net/swofty/nativebridge/representation/VariableAssignment");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(assignClass, "<init>", 
        "(Ljava/lang/String;Lnet/swofty/nativebridge/representation/Expression;)V");
    
    // Create variable name string
    jstring jvarName = env->NewStringUTF(assignment->getVariableName().c_str());
    
    // Create value expression
    jobject jvalue = createJavaExpression(env, assignment->getValue());
    
    // Create VariableAssignment object
    jobject jassignment = env->NewObject(assignClass, constructor, jvarName, jvalue);
    
    // Clean up local references
    env->DeleteLocalRef(jvarName);
    env->DeleteLocalRef(jvalue);
    
    return jassignment;
}

jobject SwoftLangJNIBridge::createJavaStringLiteral(JNIEnv* env, const std::shared_ptr<StringLiteral>& literal) {
    // Find StringLiteral class
    jclass stringClass = env->FindClass("net/swofty/nativebridge/representation/StringLiteral");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(stringClass, "<init>", "(Ljava/lang/String;)V");
    
    // Create value string
    jstring jvalue = env->NewStringUTF(literal->getValue().c_str());
    
    // Create StringLiteral object
    jobject jliteral = env->NewObject(stringClass, constructor, jvalue);
    
    // Clean up local references
    env->DeleteLocalRef(jvalue);
    
    return jliteral;
}

jobject SwoftLangJNIBridge::createJavaVariableReference(JNIEnv* env, const std::shared_ptr<VariableReference>& reference) {
    // Find VariableReference class
    jclass refClass = env->FindClass("net/swofty/nativebridge/representation/VariableReference");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(refClass, "<init>", "(Ljava/lang/String;)V");
    
    // Create name string
    jstring jname = env->NewStringUTF(reference->getName().c_str());
    
    // Create VariableReference object
    jobject jreference = env->NewObject(refClass, constructor, jname);
    
    // Clean up local references
    env->DeleteLocalRef(jname);
    
    return jreference;
}

jobject SwoftLangJNIBridge::createJavaBinaryExpression(JNIEnv* env, const std::shared_ptr<BinaryExpression>& expression) {
    // Find BinaryExpression class
    jclass binClass = env->FindClass("net/swofty/nativebridge/representation/BinaryExpression");
    
    // Find Operator enum class
    jclass operatorClass = env->FindClass("net/swofty/nativebridge/representation/BinaryExpression$Operator");
    
    // Find static valueOf method for enum
    jmethodID valueOfMethod = env->GetStaticMethodID(operatorClass, "valueOf", 
        "(Ljava/lang/String;)Lnet/swofty/nativebridge/representation/BinaryExpression$Operator;");
    
    // Convert C++ enum to Java enum
    const char* operatorName;
    switch (expression->getOperator()) {
        case BinaryExpression::Operator::EQUALS: operatorName = "EQUALS"; break;
        case BinaryExpression::Operator::NOT_EQUALS: operatorName = "NOT_EQUALS"; break;
        case BinaryExpression::Operator::LESS_THAN: operatorName = "LESS_THAN"; break;
        case BinaryExpression::Operator::GREATER_THAN: operatorName = "GREATER_THAN"; break;
        case BinaryExpression::Operator::LESS_EQUALS: operatorName = "LESS_EQUALS"; break;
        case BinaryExpression::Operator::GREATER_EQUALS: operatorName = "GREATER_EQUALS"; break;
        case BinaryExpression::Operator::AND: operatorName = "AND"; break;
        case BinaryExpression::Operator::OR: operatorName = "OR"; break;
        case BinaryExpression::Operator::IS_TYPE: operatorName = "IS_TYPE"; break;
        case BinaryExpression::Operator::IS_NOT_TYPE: operatorName = "IS_NOT_TYPE"; break;
        default: operatorName = "EQUALS"; break;
    }
    
    jstring joperatorName = env->NewStringUTF(operatorName);
    jobject joperator = env->CallStaticObjectMethod(operatorClass, valueOfMethod, joperatorName);
    env->DeleteLocalRef(joperatorName);
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(binClass, "<init>", 
        "(Lnet/swofty/nativebridge/representation/Expression;Lnet/swofty/nativebridge/representation/BinaryExpression$Operator;Lnet/swofty/nativebridge/representation/Expression;)V");
    
    // Create expression objects
    jobject jleft = createJavaExpression(env, expression->getLeft());
    jobject jright = createJavaExpression(env, expression->getRight());
    
    // Create BinaryExpression object
    jobject jbinary = env->NewObject(binClass, constructor, jleft, joperator, jright);
    
    // Clean up local references
    env->DeleteLocalRef(jleft);
    env->DeleteLocalRef(joperator);
    env->DeleteLocalRef(jright);
    
    return jbinary;
}

jobject SwoftLangJNIBridge::createJavaTypeLiteral(JNIEnv* env, const std::shared_ptr<TypeLiteral>& literal) {
    // Find TypeLiteral class
    jclass typeClass = env->FindClass("net/swofty/nativebridge/representation/TypeLiteral");
    
    // Find constructor
    jmethodID constructor = env->GetMethodID(typeClass, "<init>", "(Ljava/lang/String;)V");
    
    // Create type name string
    jstring jtypeName = env->NewStringUTF(literal->getTypeName().c_str());
    
    // Create TypeLiteral object
    jobject jtypeLiteral = env->NewObject(typeClass, constructor, jtypeName);
    
    // Clean up local references
    env->DeleteLocalRef(jtypeName);
    
    return jtypeLiteral;
}

// Keep all the existing helper methods (createJavaVariable, createJavaDataType)
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