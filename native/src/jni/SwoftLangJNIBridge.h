#pragma once
#include <jni.h>
#include <vector>
#include <memory>

// Include all AST files individually
#include "ASTNode.h"
#include "Expression.h"
#include "Statement.h"
#include "SendCommand.h"
#include "TeleportCommand.h"
#include "HaltCommand.h"
#include "IfStatement.h"
#include "BlockStatement.h"
#include "VariableAssignment.h"
#include "StringLiteral.h"
#include "VariableReference.h"
#include "BinaryExpression.h"
#include "TypeLiteral.h"
#include "ExecuteBlock.h"
#include "Command.h"
#include "Variable.h"
#include "DataType.h"

class SwoftLangJNIBridge {
public:
    // Parse SwoftLang code and return a JSON representation
    static jstring parseSwoftLang(JNIEnv* env, jstring jcode);
    
    // Parse SwoftLang code and return a Command array
    static jobjectArray parseSwoftLangToCommands(JNIEnv* env, jstring jcode);
    
    // Parse execute block and return a Java ExecuteBlock object
    static jobject parseExecuteBlock(JNIEnv* env, jstring jcode);
    
private:
    // Helper methods to convert C++ objects to Java objects
    static jobject createJavaCommand(JNIEnv* env, const std::shared_ptr<Command>& command);
    static jobject createJavaVariable(JNIEnv* env, const std::shared_ptr<Variable>& variable);
    static jobject createJavaDataType(JNIEnv* env, const std::shared_ptr<DataType>& dataType);
    
    // New methods for AST conversion - fix the function signatures
    static jobject createJavaExecuteBlock(JNIEnv* env, const std::shared_ptr<ExecuteBlock>& block);
    static jobject createJavaStatement(JNIEnv* env, const std::shared_ptr<Statement>& statement);
    static jobject createJavaExpression(JNIEnv* env, const std::shared_ptr<Expression>& expression); 
    
    // Statement creation methods
    static jobject createJavaSendCommand(JNIEnv* env, const std::shared_ptr<SendCommand>& command);
    static jobject createJavaTeleportCommand(JNIEnv* env, const std::shared_ptr<TeleportCommand>& command);
    static jobject createJavaHaltCommand(JNIEnv* env, const std::shared_ptr<HaltCommand>& command);
    static jobject createJavaIfStatement(JNIEnv* env, const std::shared_ptr<IfStatement>& statement);
    static jobject createJavaBlockStatement(JNIEnv* env, const std::shared_ptr<BlockStatement>& statement);
    static jobject createJavaVariableAssignment(JNIEnv* env, const std::shared_ptr<VariableAssignment>& assignment);
    
    // Expression creation methods
    static jobject createJavaStringLiteral(JNIEnv* env, const std::shared_ptr<StringLiteral>& literal);
    static jobject createJavaVariableReference(JNIEnv* env, const std::shared_ptr<VariableReference>& reference);
    static jobject createJavaBinaryExpression(JNIEnv* env, const std::shared_ptr<BinaryExpression>& expression);
    static jobject createJavaTypeLiteral(JNIEnv* env, const std::shared_ptr<TypeLiteral>& literal);  // Add missing declaration
};