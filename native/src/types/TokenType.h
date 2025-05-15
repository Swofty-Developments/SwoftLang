#pragma once

enum class TokenType {
    // Basic tokens
    IDENTIFIER,
    STRING_LITERAL,
    NUMBER,
    
    // Keywords
    COMMAND, 
    EVENT,
    IF,
    ELSE,
    HALT,
    SEND,
    TELEPORT,
    TO,
    IS,
    NOT,
    EITHER,
    CANCEL,  
    SET,      
    CONTAINS, 
    
    // Operators
    COLON,          // :
    EQUALS,         // =
    NOT_EQUALS,     // !=
    LESS_THAN,      // <
    GREATER_THAN,   // >
    LESS_EQUALS,    // <=
    GREATER_EQUALS, // >=
    AND,            // &&
    OR,             // ||
    DOT,            // .
    PLUS,           // +
    
    // Brackets/Parentheses
    LEFT_BRACE,     // {
    RIGHT_BRACE,    // }
    LEFT_PAREN,     // (
    RIGHT_PAREN,    // )
    LEFT_ANGLE,     // <
    RIGHT_ANGLE,    // >
    
    // Other
    PIPE,           // |
    COMMA,          // ,
    COMMENT,
    WHITESPACE,
    END_OF_FILE
};