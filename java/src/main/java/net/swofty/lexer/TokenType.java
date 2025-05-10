package net.swofty.lexer;

/**
 * Token type enumeration for SwoftLang script
 */
public enum TokenType {
    // Literals
    IDENTIFIER,
    STRING_LITERAL,
    NUMBER,

    // Keywords
    IF,
    ELSE,
    HALT,
    SEND,
    TELEPORT,
    TO,
    IS,
    NOT,
    A,

    // Operators
    EQUALS,         // =
    DOUBLE_EQUALS,  // ==
    NOT_EQUALS,     // !=
    LESS_THAN,      // <
    GREATER_THAN,   // >
    LESS_EQUALS,    // <=
    GREATER_EQUALS, // >=
    AND,            // &&
    OR,             // ||

    // Punctuation
    LEFT_BRACE,     // {
    RIGHT_BRACE,    // }
    LEFT_PAREN,     // (
    RIGHT_PAREN,    // )
    COMMA,          // ,
    DOT,            // .
    DOLLAR,         // $

    // Special
    COMMENT,
    NEWLINE,
    EOF,
    UNKNOWN
}
