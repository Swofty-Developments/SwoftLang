#include "SwoftLangJNIBridge.h"
#include "SwoftLangParser.h"
#include <memory>
#include <ExecuteBlockParser.h>
#include <Lexer.h>
#include <stdexcept>
#include <VariableReference.h>
#include <SendCommand.h>
#include <TypeLiteral.h>
#include <StringLiteral.h>
#include <TeleportCommand.h>
#include <HaltCommand.h>
#include <IfStatement.h>
#include <BlockStatement.h>
#include <VariableAssignment.h>
#include <iostream>

bool checkAndClearJNIException(JNIEnv* env, const char* context) {
    if (env->ExceptionCheck()) {
        std::cerr << "JNI Exception in " << context << std::endl;
        env->ExceptionDescribe();
        env->ExceptionClear();
        return true;
    }
    return false;
}

jstring SwoftLangJNIBridge::parseSwoftLang(JNIEnv* env, jstring jcode) {
    if (!env) {
        std::cerr << "JNIEnv is null in parseSwoftLang" << std::endl;
        return NULL;
    }
    
    if (!jcode) {
        std::cerr << "jcode is null in parseSwoftLang" << std::endl;
        jclass exceptionClass = env->FindClass("java/lang/NullPointerException");
        if (exceptionClass) {
            env->ThrowNew(exceptionClass, "Input code is null");
        }
        return NULL;
    }
    
    // Convert Java string to C++ string
    const char* codeChars = env->GetStringUTFChars(jcode, NULL);
    if (!codeChars) {
        std::cerr << "Failed to get string chars" << std::endl;
        return NULL;
    }
    
    std::string code;
    try {
        code = std::string(codeChars);
    } catch (...) {
        env->ReleaseStringUTFChars(jcode, codeChars);
        return NULL;
    }
    
    env->ReleaseStringUTFChars(jcode, codeChars);
    
    try {
        // Parse the SwoftLang code
        std::vector<std::shared_ptr<Command>> commands = SwoftLangParser::parseCommands(code);
        
        // Convert to JSON
        std::string json = SwoftLangParser::commandsToJson(commands);
        
        // Return the JSON as a Java string
        jstring result = env->NewStringUTF(json.c_str());
        if (!result) {
            std::cerr << "Failed to create result string" << std::endl;
        }
        return result;
    } catch (const std::exception& e) {
        std::cerr << "Exception in parseSwoftLang: " << e.what() << std::endl;
        // If there was an error, return an error message
        std::string errorMsg = "{\"error\": \"" + std::string(e.what()) + "\"}";
        return env->NewStringUTF(errorMsg.c_str());
    } catch (...) {
        std::cerr << "Unknown exception in parseSwoftLang" << std::endl;
        return env->NewStringUTF("{\"error\": \"Unknown error\"}");
    }
}

jobjectArray SwoftLangJNIBridge::parseSwoftLangToCommands(JNIEnv* env, jstring jcode) {
    if (!env) {
        std::cerr << "JNIEnv is null in parseSwoftLangToCommands" << std::endl;
        return NULL;
    }
    
    // Check if jcode is null
    if (!jcode) {
        std::cerr << "jcode is null" << std::endl;
        jclass exceptionClass = env->FindClass("java/lang/NullPointerException");
        if (exceptionClass) {
            env->ThrowNew(exceptionClass, "Input code is null");
        }
        return NULL;
    }
    
    // Convert Java string to C++ string
    const char* codeChars = env->GetStringUTFChars(jcode, NULL);
    if (!codeChars) {
        std::cerr << "Failed to get string chars" << std::endl;
        jclass exceptionClass = env->FindClass("java/lang/OutOfMemoryError");
        if (exceptionClass) {
            env->ThrowNew(exceptionClass, "Failed to get string chars");
        }
        return NULL;
    }
    
    std::string code;
    try {
        code = std::string(codeChars);
    } catch (...) {
        env->ReleaseStringUTFChars(jcode, codeChars);
        return NULL;
    }
    
    env->ReleaseStringUTFChars(jcode, codeChars);
    
    try {
        // Parse the SwoftLang code
        std::vector<std::shared_ptr<Command>> commands;
        try {
            commands = SwoftLangParser::parseCommands(code);
        } catch (const std::exception& e) {
            std::cerr << "Parser exception: " << e.what() << std::endl;
            throw;
        }
        
        // Find Command class in the correct package
        jclass commandClass = env->FindClass("net/swofty/nativebridge/representation/Command");
        if (!commandClass) {
            std::cerr << "Failed to find Command class" << std::endl;
            checkAndClearJNIException(env, "FindClass Command");
            jclass exceptionClass = env->FindClass("java/lang/ClassNotFoundException");
            if (exceptionClass) {
                env->ThrowNew(exceptionClass, "Command class not found");
            }
            return NULL;
        }
        
        // Create an array of Command objects
        jobjectArray result = env->NewObjectArray(commands.size(), commandClass, NULL);
        if (!result) {
            std::cerr << "Failed to create object array" << std::endl;
            checkAndClearJNIException(env, "NewObjectArray");
            jclass exceptionClass = env->FindClass("java/lang/OutOfMemoryError");
            if (exceptionClass) {
                env->ThrowNew(exceptionClass, "Failed to create object array");
            }
            return NULL;
        }
        
        // Fill the array with Command objects
        for (size_t i = 0; i < commands.size(); i++) {
            if (!commands[i]) {
                std::cerr << "Null command at index " << i << std::endl;
                continue;
            }
            
            jobject jcommand = NULL;
            try {
                jcommand = createJavaCommand(env, commands[i]);
            } catch (const std::exception& e) {
                std::cerr << "Exception creating command " << i << ": " << e.what() << std::endl;
                continue;
            } catch (...) {
                std::cerr << "Unknown exception creating command " << i << std::endl;
                continue;
            }
            
            if (!jcommand) {
                std::cerr << "Failed to create Java command object for index " << i << std::endl;
                continue;
            }
            
            env->SetObjectArrayElement(result, i, jcommand);
            if (checkAndClearJNIException(env, "SetObjectArrayElement")) {
                env->DeleteLocalRef(jcommand);
                continue;
            }
            
            env->DeleteLocalRef(jcommand);
        }
        
        return result;
    } catch (const std::exception& e) {
        std::cerr << "Exception in parseSwoftLangToCommands: " << e.what() << std::endl;
        // If there was an error, throw a Java exception
        jclass exceptionClass = env->FindClass("java/lang/RuntimeException");
        if (exceptionClass) {
            env->ThrowNew(exceptionClass, e.what());
        }
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in parseSwoftLangToCommands" << std::endl;
        jclass exceptionClass = env->FindClass("java/lang/RuntimeException");
        if (exceptionClass) {
            env->ThrowNew(exceptionClass, "Unknown error in native parser");
        }
        return NULL;
    }
}

jobject SwoftLangJNIBridge::parseExecuteBlock(JNIEnv* env, jstring jcode) {
    if (!env || !jcode) {
        std::cerr << "Null pointer in parseExecuteBlock" << std::endl;
        return NULL;
    }
    
    // Convert Java string to C++ string
    const char* codeChars = env->GetStringUTFChars(jcode, NULL);
    if (!codeChars) {
        std::cerr << "Failed to get string chars in parseExecuteBlock" << std::endl;
        return NULL;
    }
    
    std::string code;
    try {
        code = std::string(codeChars);
    } catch (...) {
        env->ReleaseStringUTFChars(jcode, codeChars);
        return NULL;
    }
    
    env->ReleaseStringUTFChars(jcode, codeChars);
    
    try {
        // Create lexer and tokenize
        Lexer lexer(code);
        std::vector<Token> tokens = lexer.tokenize();
        
        // Create execute block parser
        ExecuteBlockParser parser(tokens);
        auto executeBlock = parser.parseExecuteBlock();
        
        if (!executeBlock) {
            std::cerr << "Parser returned null execute block" << std::endl;
            return NULL;
        }
        
        // Convert to Java object
        return createJavaExecuteBlock(env, executeBlock);
    } catch (const std::exception& e) {
        std::cerr << "Exception in parseExecuteBlock: " << e.what() << std::endl;
        // If there was an error, throw a Java exception
        jclass exceptionClass = env->FindClass("java/lang/RuntimeException");
        if (exceptionClass) {
            env->ThrowNew(exceptionClass, e.what());
        }
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in parseExecuteBlock" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaCommand(JNIEnv* env, const std::shared_ptr<Command>& command) {
    if (!env || !command) {
        std::cerr << "Null pointer in createJavaCommand" << std::endl;
        if (env) {
            jclass exceptionClass = env->FindClass("java/lang/NullPointerException");
            if (exceptionClass) {
                env->ThrowNew(exceptionClass, "Command is null");
            }
        }
        return NULL;
    }
    
    try {
        // Find Command class
        jclass commandClass = env->FindClass("net/swofty/nativebridge/representation/Command");
        if (!commandClass) {
            checkAndClearJNIException(env, "FindClass Command");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(commandClass, "<init>", "(Ljava/lang/String;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID Command constructor");
            return NULL;
        }
        
        // Create Command object
        const std::string& commandName = command->getName();
        jstring jname = env->NewStringUTF(commandName.c_str());
        if (!jname) {
            std::cerr << "Failed to create command name string" << std::endl;
            return NULL;
        }
        
        jobject jcommand = env->NewObject(commandClass, constructor, jname);
        env->DeleteLocalRef(jname);
        
        if (!jcommand) {
            checkAndClearJNIException(env, "NewObject Command");
            return NULL;
        }
        
        // Set permission
        try {
            jmethodID setPermission = env->GetMethodID(commandClass, "setPermission", "(Ljava/lang/String;)V");
            if (setPermission) {
                const std::string& permStr = command->getPermission();
                jstring jpermission = env->NewStringUTF(permStr.c_str());
                if (jpermission) {
                    env->CallVoidMethod(jcommand, setPermission, jpermission);
                    env->DeleteLocalRef(jpermission);
                    checkAndClearJNIException(env, "CallVoidMethod setPermission");
                }
            }
        } catch (...) {
            std::cerr << "Exception in setPermission" << std::endl;
        }
        
        // Set description
        try {
            jmethodID setDescription = env->GetMethodID(commandClass, "setDescription", "(Ljava/lang/String;)V");
            if (setDescription) {
                const std::string& descStr = command->getDescription();
                jstring jdescription = env->NewStringUTF(descStr.c_str());
                if (jdescription) {
                    env->CallVoidMethod(jcommand, setDescription, jdescription);
                    env->DeleteLocalRef(jdescription);
                    checkAndClearJNIException(env, "CallVoidMethod setDescription");
                }
            }
        } catch (...) {
            std::cerr << "Exception in setDescription" << std::endl;
        }
        
        // Add arguments
        try {
            jmethodID addArgument = env->GetMethodID(commandClass, "addArgument", "(Lnet/swofty/nativebridge/representation/Variable;)V");
            if (addArgument) {
                const auto& arguments = command->getArguments();
                for (const auto& arg : arguments) {
                    if (!arg) continue;
                    
                    jobject jarg = createJavaVariable(env, arg);
                    if (jarg) {
                        env->CallVoidMethod(jcommand, addArgument, jarg);
                        env->DeleteLocalRef(jarg);
                        checkAndClearJNIException(env, "CallVoidMethod addArgument");
                    }
                }
            }
        } catch (...) {
            std::cerr << "Exception in addArgument" << std::endl;
        }
        
        // Set execute block if present
        try {
            auto executeBlock = command->getExecuteBlock();
            if (executeBlock) {
                jmethodID setExecuteBlock = env->GetMethodID(commandClass, "setExecuteBlock", 
                    "(Lnet/swofty/nativebridge/representation/ExecuteBlock;)V");
                if (setExecuteBlock) {
                    jobject jexecuteBlock = createJavaExecuteBlock(env, executeBlock);
                    if (jexecuteBlock) {
                        env->CallVoidMethod(jcommand, setExecuteBlock, jexecuteBlock);
                        env->DeleteLocalRef(jexecuteBlock);
                        checkAndClearJNIException(env, "CallVoidMethod setExecuteBlock");
                    }
                }
            }
        } catch (...) {
            std::cerr << "Exception in setExecuteBlock" << std::endl;
        }
        
        return jcommand;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaCommand: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaCommand" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaExecuteBlock(JNIEnv* env, const std::shared_ptr<ExecuteBlock>& block) {
    if (!env || !block) {
        std::cerr << "Null pointer in createJavaExecuteBlock" << std::endl;
        return NULL;
    }
    
    try {
        // Find ExecuteBlock class
        jclass executeBlockClass = env->FindClass("net/swofty/nativebridge/representation/ExecuteBlock");
        if (!executeBlockClass) {
            checkAndClearJNIException(env, "FindClass ExecuteBlock");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(executeBlockClass, "<init>", "()V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID ExecuteBlock constructor");
            return NULL;
        }
        
        // Create ExecuteBlock object
        jobject jblock = env->NewObject(executeBlockClass, constructor);
        if (!jblock) {
            checkAndClearJNIException(env, "NewObject ExecuteBlock");
            return NULL;
        }
        
        // Add statements
        jmethodID addStatement = env->GetMethodID(executeBlockClass, "addStatement", 
            "(Lnet/swofty/nativebridge/execution/Statement;)V");
        if (!addStatement) {
            checkAndClearJNIException(env, "GetMethodID addStatement");
            env->DeleteLocalRef(jblock);
            return NULL;
        }
        
        const auto& statements = block->getStatements();
        for (const auto& statement : statements) {
            if (!statement) continue;
            
            try {
                jobject jstatement = createJavaStatement(env, statement);
                if (jstatement) {
                    env->CallVoidMethod(jblock, addStatement, jstatement);
                    env->DeleteLocalRef(jstatement);
                    checkAndClearJNIException(env, "CallVoidMethod addStatement");
                }
            } catch (...) {
                std::cerr << "Exception creating statement in execute block" << std::endl;
            }
        }
        
        return jblock;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaExecuteBlock: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaExecuteBlock" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaStatement(JNIEnv* env, const std::shared_ptr<Statement>& statement) {
    if (!env || !statement) {
        std::cerr << "Null pointer in createJavaStatement" << std::endl;
        return NULL;
    }
    
    try {
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
        std::cerr << "Unknown statement type" << std::endl;
        throw std::runtime_error("Unknown statement type");
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaStatement: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaStatement" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaExpression(JNIEnv* env, const std::shared_ptr<Expression>& expression) {
    if (!env || !expression) {
        std::cerr << "Null pointer in createJavaExpression" << std::endl;
        return NULL;
    }
    
    try {
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
        std::cerr << "Unknown expression type" << std::endl;
        throw std::runtime_error("Unknown expression type");
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaExpression: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaExpression" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaSendCommand(JNIEnv* env, const std::shared_ptr<SendCommand>& command) {
    if (!env || !command) {
        std::cerr << "Null pointer in createJavaSendCommand" << std::endl;
        return NULL;
    }
    
    try {
        // Find SendCommand class
        jclass sendClass = env->FindClass("net/swofty/nativebridge/execution/commands/SendCommand");
        if (!sendClass) {
            checkAndClearJNIException(env, "FindClass SendCommand");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(sendClass, "<init>", 
            "(Lnet/swofty/nativebridge/execution/Expression;Lnet/swofty/nativebridge/execution/Expression;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID SendCommand constructor");
            return NULL;
        }
        
        // Create expression objects
        jobject jmessage = NULL;
        auto messageExpr = command->getMessage();
        if (messageExpr) {
            jmessage = createJavaExpression(env, messageExpr);
        }
        
        jobject jtarget = NULL;
        auto targetExpr = command->getTarget();
        if (targetExpr) {
            jtarget = createJavaExpression(env, targetExpr);
        }
        
        // Create SendCommand object
        jobject jsend = env->NewObject(sendClass, constructor, jmessage, jtarget);
        if (!jsend) {
            checkAndClearJNIException(env, "NewObject SendCommand");
            if (jmessage) env->DeleteLocalRef(jmessage);
            if (jtarget) env->DeleteLocalRef(jtarget);
            return NULL;
        }
        
        // Clean up local references
        if (jmessage) env->DeleteLocalRef(jmessage);
        if (jtarget) env->DeleteLocalRef(jtarget);
        
        return jsend;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaSendCommand: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaSendCommand" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaTeleportCommand(JNIEnv* env, const std::shared_ptr<TeleportCommand>& command) {
    if (!env || !command) {
        std::cerr << "Null pointer in createJavaTeleportCommand" << std::endl;
        return NULL;
    }
    
    try {
        // Find TeleportCommand class
        jclass teleportClass = env->FindClass("net/swofty/nativebridge/execution/commands/TeleportCommand");
        if (!teleportClass) {
            checkAndClearJNIException(env, "FindClass TeleportCommand");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(teleportClass, "<init>", 
            "(Lnet/swofty/nativebridge/execution/Expression;Lnet/swofty/nativebridge/execution/Expression;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID TeleportCommand constructor");
            return NULL;
        }
        
        // Create expression objects
        jobject jentity = NULL;
        auto entityExpr = command->getEntity();
        if (entityExpr) {
            jentity = createJavaExpression(env, entityExpr);
        }
        
        jobject jtarget = NULL;
        auto targetExpr = command->getTarget();
        if (targetExpr) {
            jtarget = createJavaExpression(env, targetExpr);
        }
        
        // Create TeleportCommand object
        jobject jteleport = env->NewObject(teleportClass, constructor, jentity, jtarget);
        if (!jteleport) {
            checkAndClearJNIException(env, "NewObject TeleportCommand");
            if (jentity) env->DeleteLocalRef(jentity);
            if (jtarget) env->DeleteLocalRef(jtarget);
            return NULL;
        }
        
        // Clean up local references
        if (jentity) env->DeleteLocalRef(jentity);
        if (jtarget) env->DeleteLocalRef(jtarget);
        
        return jteleport;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaTeleportCommand: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaTeleportCommand" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaHaltCommand(JNIEnv* env, const std::shared_ptr<HaltCommand>& command) {
    if (!env || !command) {
        std::cerr << "Null pointer in createJavaHaltCommand" << std::endl;
        return NULL;
    }
    
    try {
        // Find HaltCommand class
        jclass haltClass = env->FindClass("net/swofty/nativebridge/execution/commands/HaltCommand");
        if (!haltClass) {
            checkAndClearJNIException(env, "FindClass HaltCommand");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(haltClass, "<init>", "()V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID HaltCommand constructor");
            return NULL;
        }
        
        // Create HaltCommand object
        jobject jhalt = env->NewObject(haltClass, constructor);
        if (!jhalt) {
            checkAndClearJNIException(env, "NewObject HaltCommand");
        }
        return jhalt;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaHaltCommand: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaHaltCommand" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaIfStatement(JNIEnv* env, const std::shared_ptr<IfStatement>& statement) {
    if (!env || !statement) {
        std::cerr << "Null pointer in createJavaIfStatement" << std::endl;
        return NULL;
    }
    
    try {
        // Find IfStatement class
        jclass ifClass = env->FindClass("net/swofty/nativebridge/execution/commands/IfStatement");
        if (!ifClass) {
            checkAndClearJNIException(env, "FindClass IfStatement");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(ifClass, "<init>", 
            "(Lnet/swofty/nativebridge/execution/Expression;Lnet/swofty/nativebridge/execution/Statement;Lnet/swofty/nativebridge/execution/Statement;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID IfStatement constructor");
            return NULL;
        }
        
        // Create objects
        jobject jcondition = NULL;
        auto condExpr = statement->getCondition();
        if (condExpr) {
            jcondition = createJavaExpression(env, condExpr);
        }
        
        jobject jthen = NULL;
        auto thenStmt = statement->getThenStatement();
        if (thenStmt) {
            jthen = createJavaStatement(env, thenStmt);
        }
        
        jobject jelse = NULL;
        auto elseStmt = statement->getElseStatement();
        if (elseStmt) {
            jelse = createJavaStatement(env, elseStmt);
        }
        
        // Create IfStatement object
        jobject jif = env->NewObject(ifClass, constructor, jcondition, jthen, jelse);
        if (!jif) {
            checkAndClearJNIException(env, "NewObject IfStatement");
            if (jcondition) env->DeleteLocalRef(jcondition);
            if (jthen) env->DeleteLocalRef(jthen);
            if (jelse) env->DeleteLocalRef(jelse);
            return NULL;
        }
        
        // Clean up local references
        if (jcondition) env->DeleteLocalRef(jcondition);
        if (jthen) env->DeleteLocalRef(jthen);
        if (jelse) env->DeleteLocalRef(jelse);
        
        return jif;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaIfStatement: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaIfStatement" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaBlockStatement(JNIEnv* env, const std::shared_ptr<BlockStatement>& statement) {
    if (!env || !statement) {
        std::cerr << "Null pointer in createJavaBlockStatement" << std::endl;
        return NULL;
    }
    
    try {
        // Find BlockStatement class
        jclass blockClass = env->FindClass("net/swofty/nativebridge/execution/BlockStatement");
        if (!blockClass) {
            checkAndClearJNIException(env, "FindClass BlockStatement");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(blockClass, "<init>", "()V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID BlockStatement constructor");
            return NULL;
        }
        
        // Create BlockStatement object
        jobject jblock = env->NewObject(blockClass, constructor);
        if (!jblock) {
            checkAndClearJNIException(env, "NewObject BlockStatement");
            return NULL;
        }
        
        // Add statements
        jmethodID addStatement = env->GetMethodID(blockClass, "addStatement", 
            "(Lnet/swofty/nativebridge/execution/Statement;)V");
        if (!addStatement) {
            checkAndClearJNIException(env, "GetMethodID addStatement");
            env->DeleteLocalRef(jblock);
            return NULL;
        }
        
        const auto& statements = statement->getStatements();
        for (const auto& stmt : statements) {
            if (!stmt) continue;
            
            try {
                jobject jstatement = createJavaStatement(env, stmt);
                if (jstatement) {
                    env->CallVoidMethod(jblock, addStatement, jstatement);
                    env->DeleteLocalRef(jstatement);
                    checkAndClearJNIException(env, "CallVoidMethod addStatement");
                }
            } catch (...) {
                std::cerr << "Exception adding statement to block" << std::endl;
            }
        }
        
        return jblock;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaBlockStatement: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaBlockStatement" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaVariableAssignment(JNIEnv* env, const std::shared_ptr<VariableAssignment>& assignment) {
    if (!env || !assignment) {
        std::cerr << "Null pointer in createJavaVariableAssignment" << std::endl;
        return NULL;
    }
    
    try {
        // Find VariableAssignment class
        jclass assignClass = env->FindClass("net/swofty/nativebridge/execution/commands/VariableAssignment");
        if (!assignClass) {
            checkAndClearJNIException(env, "FindClass VariableAssignment");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(assignClass, "<init>", 
            "(Ljava/lang/String;Lnet/swofty/nativebridge/execution/Expression;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID VariableAssignment constructor");
            return NULL;
        }
        
        // Create variable name string
        const std::string& varName = assignment->getVariableName();
        jstring jvarName = env->NewStringUTF(varName.c_str());
        if (!jvarName) {
            std::cerr << "Failed to create variable name string" << std::endl;
            return NULL;
        }
        
        // Create value expression
        jobject jvalue = NULL;
        auto valueExpr = assignment->getValue();
        if (valueExpr) {
            jvalue = createJavaExpression(env, valueExpr);
        }
        
        // Create VariableAssignment object
        jobject jassignment = env->NewObject(assignClass, constructor, jvarName, jvalue);
        if (!jassignment) {
            checkAndClearJNIException(env, "NewObject VariableAssignment");
            env->DeleteLocalRef(jvarName);
            if (jvalue) env->DeleteLocalRef(jvalue);
            return NULL;
        }
        
        // Clean up local references
        env->DeleteLocalRef(jvarName);
        if (jvalue) env->DeleteLocalRef(jvalue);
        
        return jassignment;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaVariableAssignment: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaVariableAssignment" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaStringLiteral(JNIEnv* env, const std::shared_ptr<StringLiteral>& literal) {
    if (!env || !literal) {
        std::cerr << "Null pointer in createJavaStringLiteral" << std::endl;
        return NULL;
    }
    
    try {
        // Find StringLiteral class
        jclass stringClass = env->FindClass("net/swofty/nativebridge/execution/expressions/StringLiteral");
        if (!stringClass) {
            checkAndClearJNIException(env, "FindClass StringLiteral");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(stringClass, "<init>", "(Ljava/lang/String;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID StringLiteral constructor");
            return NULL;
        }
        
        // Create value string
        const std::string& value = literal->getValue();
        jstring jvalue = env->NewStringUTF(value.c_str());
        if (!jvalue) {
            std::cerr << "Failed to create string literal value" << std::endl;
            return NULL;
        }
        
        // Create StringLiteral object
        jobject jliteral = env->NewObject(stringClass, constructor, jvalue);
        if (!jliteral) {
            checkAndClearJNIException(env, "NewObject StringLiteral");
            env->DeleteLocalRef(jvalue);
            return NULL;
        }
        
        // Clean up local references
        env->DeleteLocalRef(jvalue);
        
        return jliteral;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaStringLiteral: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaStringLiteral" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaVariableReference(JNIEnv* env, const std::shared_ptr<VariableReference>& reference) {
    if (!env || !reference) {
        std::cerr << "Null pointer in createJavaVariableReference" << std::endl;
        return NULL;
    }
    
    try {
        // Find VariableReference class
        jclass refClass = env->FindClass("net/swofty/nativebridge/execution/expressions/VariableReference");
        if (!refClass) {
            checkAndClearJNIException(env, "FindClass VariableReference");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(refClass, "<init>", "(Ljava/lang/String;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID VariableReference constructor");
            return NULL;
        }
        
        // Create name string
        const std::string& name = reference->getName();
        jstring jname = env->NewStringUTF(name.c_str());
        if (!jname) {
            std::cerr << "Failed to create variable reference name" << std::endl;
            return NULL;
        }
        
        // Create VariableReference object
        jobject jreference = env->NewObject(refClass, constructor, jname);
        if (!jreference) {
            checkAndClearJNIException(env, "NewObject VariableReference");
            env->DeleteLocalRef(jname);
            return NULL;
        }
        
        // Clean up local references
        env->DeleteLocalRef(jname);
        
        return jreference;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaVariableReference: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaVariableReference" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaBinaryExpression(JNIEnv* env, const std::shared_ptr<BinaryExpression>& expression) {
    if (!env || !expression) {
        std::cerr << "Null pointer in createJavaBinaryExpression" << std::endl;
        return NULL;
    }
    
    try {
        // Find BinaryExpression class
        jclass binClass = env->FindClass("net/swofty/nativebridge/execution/expressions/BinaryExpression");
        if (!binClass) {
            checkAndClearJNIException(env, "FindClass BinaryExpression");
            return NULL;
        }
        
        // Find Operator enum class
        jclass operatorClass = env->FindClass("net/swofty/nativebridge/execution/expressions/BinaryExpression$Operator");
        if (!operatorClass) {
            checkAndClearJNIException(env, "FindClass BinaryExpression$Operator");
            return NULL;
        }
        
        // Find static valueOf method for enum
        jmethodID valueOfMethod = env->GetStaticMethodID(operatorClass, "valueOf", 
            "(Ljava/lang/String;)Lnet/swofty/nativebridge/execution/expressions/BinaryExpression$Operator;");
        if (!valueOfMethod) {
            checkAndClearJNIException(env, "GetStaticMethodID valueOf");
            return NULL;
        }
        
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
        if (!joperatorName) {
            std::cerr << "Failed to create operator name string" << std::endl;
            return NULL;
        }
        
        jobject joperator = env->CallStaticObjectMethod(operatorClass, valueOfMethod, joperatorName);
        env->DeleteLocalRef(joperatorName);
        
        if (!joperator) {
            checkAndClearJNIException(env, "CallStaticObjectMethod valueOf");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(binClass, "<init>", 
            "(Lnet/swofty/nativebridge/execution/Expression;Lnet/swofty/nativebridge/execution/expressions/BinaryExpression$Operator;Lnet/swofty/nativebridge/execution/Expression;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID BinaryExpression constructor");
            env->DeleteLocalRef(joperator);
            return NULL;
        }
        
        // Create expression objects
        jobject jleft = NULL;
        auto leftExpr = expression->getLeft();
        if (leftExpr) {
            jleft = createJavaExpression(env, leftExpr);
        }
        
        jobject jright = NULL;
        auto rightExpr = expression->getRight();
        if (rightExpr) {
            jright = createJavaExpression(env, rightExpr);
        }
        
        // Create BinaryExpression object
        jobject jbinary = env->NewObject(binClass, constructor, jleft, joperator, jright);
        if (!jbinary) {
            checkAndClearJNIException(env, "NewObject BinaryExpression");
            if (jleft) env->DeleteLocalRef(jleft);
            env->DeleteLocalRef(joperator);
            if (jright) env->DeleteLocalRef(jright);
            return NULL;
        }
        
        // Clean up local references
        if (jleft) env->DeleteLocalRef(jleft);
        env->DeleteLocalRef(joperator);
        if (jright) env->DeleteLocalRef(jright);
        
        return jbinary;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaBinaryExpression: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaBinaryExpression" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaTypeLiteral(JNIEnv* env, const std::shared_ptr<TypeLiteral>& literal) {
    if (!env || !literal) {
        std::cerr << "Null pointer in createJavaTypeLiteral" << std::endl;
        return NULL;
    }
    
    try {
        // Find TypeLiteral class
        jclass typeClass = env->FindClass("net/swofty/nativebridge/execution/expressions/TypeLiteral");
        if (!typeClass) {
            checkAndClearJNIException(env, "FindClass TypeLiteral");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(typeClass, "<init>", "(Ljava/lang/String;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID TypeLiteral constructor");
            return NULL;
        }
        
        // Create type name string
        const std::string& typeName = literal->getTypeName();
        jstring jtypeName = env->NewStringUTF(typeName.c_str());
        if (!jtypeName) {
            std::cerr << "Failed to create type name string" << std::endl;
            return NULL;
        }
        
        // Create TypeLiteral object
        jobject jtypeLiteral = env->NewObject(typeClass, constructor, jtypeName);
        if (!jtypeLiteral) {
            checkAndClearJNIException(env, "NewObject TypeLiteral");
            env->DeleteLocalRef(jtypeName);
            return NULL;
        }
        
        // Clean up local references
        env->DeleteLocalRef(jtypeName);
        
        return jtypeLiteral;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaTypeLiteral: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaTypeLiteral" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaVariable(JNIEnv* env, const std::shared_ptr<Variable>& variable) {
    if (!env || !variable) {
        std::cerr << "Null pointer in createJavaVariable" << std::endl;
        return NULL;
    }
    
    try {
        // Find Variable class
        jclass variableClass = env->FindClass("net/swofty/nativebridge/representation/Variable");
        if (!variableClass) {
            checkAndClearJNIException(env, "FindClass Variable");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(variableClass, "<init>", "(Ljava/lang/String;Lnet/swofty/nativebridge/representation/DataType;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID Variable constructor");
            return NULL;
        }
        
        // Create DataType object
        jobject jdataType = createJavaDataType(env, variable->getType());
        if (!jdataType) {
            std::cerr << "Failed to create Java DataType" << std::endl;
            return NULL;
        }
        
        // Create Variable object
        const std::string& name = variable->getName();
        jstring jname = env->NewStringUTF(name.c_str());
        if (!jname) {
            std::cerr << "Failed to create variable name string" << std::endl;
            env->DeleteLocalRef(jdataType);
            return NULL;
        }
        
        jobject jvariable = env->NewObject(variableClass, constructor, jname, jdataType);
        env->DeleteLocalRef(jname);
        env->DeleteLocalRef(jdataType);
        
        if (!jvariable) {
            checkAndClearJNIException(env, "NewObject Variable");
            return NULL;
        }
        
        // Set default value if present
        if (variable->getHasDefault()) {
            jmethodID setDefault = env->GetMethodID(variableClass, "setDefault", "(Ljava/lang/String;)V");
            if (setDefault) {
                const std::string& defaultValue = variable->getDefaultValue();
                jstring jdefault = env->NewStringUTF(defaultValue.c_str());
                if (jdefault) {
                    env->CallVoidMethod(jvariable, setDefault, jdefault);
                    env->DeleteLocalRef(jdefault);
                    checkAndClearJNIException(env, "CallVoidMethod setDefault");
                }
            }
        }
        
        return jvariable;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaVariable: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaVariable" << std::endl;
        return NULL;
    }
}

jobject SwoftLangJNIBridge::createJavaDataType(JNIEnv* env, const std::shared_ptr<DataType>& dataType) {
    if (!env || !dataType) {
        std::cerr << "Null pointer in createJavaDataType" << std::endl;
        return NULL;
    }
    
    try {
        // Find DataType class
        jclass dataTypeClass = env->FindClass("net/swofty/nativebridge/representation/DataType");
        if (!dataTypeClass) {
            checkAndClearJNIException(env, "FindClass DataType");
            return NULL;
        }
        
        // Find BaseType enum
        jclass baseTypeClass = env->FindClass("net/swofty/nativebridge/representation/BaseType");
        if (!baseTypeClass) {
            checkAndClearJNIException(env, "FindClass BaseType");
            return NULL;
        }
        
        // Find static valueOf method for enum
        jmethodID valueOfMethod = env->GetStaticMethodID(baseTypeClass, "valueOf", "(Ljava/lang/String;)Lnet/swofty/nativebridge/representation/BaseType;");
        if (!valueOfMethod) {
            checkAndClearJNIException(env, "GetStaticMethodID valueOf");
            return NULL;
        }
        
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
        if (!jtypeName) {
            std::cerr << "Failed to create type name string" << std::endl;
            return NULL;
        }
        
        jobject baseType = env->CallStaticObjectMethod(baseTypeClass, valueOfMethod, jtypeName);
        env->DeleteLocalRef(jtypeName);
        
        if (!baseType) {
            checkAndClearJNIException(env, "CallStaticObjectMethod valueOf");
            return NULL;
        }
        
        // Find constructor
        jmethodID constructor = env->GetMethodID(dataTypeClass, "<init>", "(Lnet/swofty/nativebridge/representation/BaseType;)V");
        if (!constructor) {
            checkAndClearJNIException(env, "GetMethodID DataType constructor");
            env->DeleteLocalRef(baseType);
            return NULL;
        }
        
        // Create DataType object
        jobject jdataType = env->NewObject(dataTypeClass, constructor, baseType);
        env->DeleteLocalRef(baseType);
        
        if (!jdataType) {
            checkAndClearJNIException(env, "NewObject DataType");
            return NULL;
        }
        
        // Add subtypes if it's an EITHER type
        if (dataType->getBaseType() == BaseType::EITHER) {
            jmethodID addSubType = env->GetMethodID(dataTypeClass, "addSubType", "(Lnet/swofty/nativebridge/representation/DataType;)V");
            if (addSubType) {
                const auto& subTypes = dataType->getSubTypes();
                for (const auto& subType : subTypes) {
                    if (!subType) continue;
                    
                    jobject jsubType = createJavaDataType(env, subType);
                    if (jsubType) {
                        env->CallVoidMethod(jdataType, addSubType, jsubType);
                        env->DeleteLocalRef(jsubType);
                        checkAndClearJNIException(env, "CallVoidMethod addSubType");
                    }
                }
            }
        }
        
        return jdataType;
    } catch (const std::exception& e) {
        std::cerr << "Exception in createJavaDataType: " << e.what() << std::endl;
        return NULL;
    } catch (...) {
        std::cerr << "Unknown exception in createJavaDataType" << std::endl;
        return NULL;
    }
}