#pragma once

enum class TokenType {
    IDENTIFIER,
    STRING_LITERAL,
    NUMBER,
    COLON,
    EQUALS,
    DOT,
    LEFT_BRACE,
    RIGHT_BRACE,
    LEFT_ANGLE,
    RIGHT_ANGLE,
    PIPE,
    COMMA,
    COMMENT,
    WHITESPACE,
    END_OF_FILE
};