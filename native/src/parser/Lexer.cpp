#include "Lexer.h"
#include <cctype>

Lexer::Lexer(const std::string& source) : source(source) {}

char Lexer::peek() const {
    if (isAtEnd()) return '\0';
    return source[position];
}

char Lexer::advance() {
    char current = peek();
    position++;
    
    if (current == '\n') {
        line++;
        column = 1;
    } else {
        column++;
    }
    
    return current;
}

bool Lexer::isAtEnd() const {
    return position >= source.length();
}

void Lexer::skipWhitespace() {
    while (!isAtEnd()) {
        char c = peek();
        // Only skip spaces and tabs, NOT newlines
        if (c == ' ' || c == '\t' || c == '\r') {
            advance();
        } else {
            break;
        }
    }
}

Token Lexer::scanToken() {
    skipWhitespace();
    
    if (isAtEnd()) {
        return Token(TokenType::END_OF_FILE, "", line, column);
    }
    
    char c = peek();
    
    // Handle newlines as tokens
    if (c == '\n') {
        int startColumn = column;
        advance();
        return Token(TokenType::WHITESPACE, "\n", line - 1, startColumn);
    }
    
    if (std::isalpha(c) || c == '_') {
        return scanIdentifier();
    }
    
    if (std::isdigit(c)) {
        return scanNumber();
    }
    
    switch (c) {
        case '"': return scanString();
        case '/': 
            if (position + 1 < source.length() && source[position + 1] == '/') {
                return scanComment();
            }
            break;
        case ':': 
            advance();
            return Token(TokenType::COLON, ":", line, column - 1);
        case '=': 
            advance();
            return Token(TokenType::EQUALS, "=", line, column - 1);
        case '{': 
            advance();
            return Token(TokenType::LEFT_BRACE, "{", line, column - 1);
        case '}': 
            advance();
            return Token(TokenType::RIGHT_BRACE, "}", line, column - 1);
        case '<': 
            advance();
            return Token(TokenType::LEFT_ANGLE, "<", line, column - 1);
        case '>': 
            advance();
            return Token(TokenType::RIGHT_ANGLE, ">", line, column - 1);
        case '|': 
            advance();
            return Token(TokenType::PIPE, "|", line, column - 1);
        case ',': 
            advance();
            return Token(TokenType::COMMA, ",", line, column - 1);
    }
    
    // Handle unexpected character
    std::string errChar(1, advance());
    return Token(TokenType::WHITESPACE, errChar, line, column - 1);
}

Token Lexer::scanIdentifier() {
    int startColumn = column;
    std::string value;
    
    while (!isAtEnd() && (std::isalnum(peek()) || peek() == '_')) {
        value += advance();
    }
    
    return Token(TokenType::IDENTIFIER, value, line, startColumn);
}

Token Lexer::scanString() {
    int startColumn = column;
    advance(); // Skip opening quote
    
    std::string value;
    while (!isAtEnd() && peek() != '"') {
        if (peek() == '\\' && position + 1 < source.length()) {
            advance(); // Skip backslash
            switch (peek()) {
                case 'n': value += '\n'; break;
                case 't': value += '\t'; break;
                case 'r': value += '\r'; break;
                case '"': value += '"'; break;
                case '\\': value += '\\'; break;
                default: value += peek();
            }
            advance();
        } else {
            value += advance();
        }
    }
    
    if (isAtEnd()) {
        // Error: unterminated string
        return Token(TokenType::STRING_LITERAL, value, line, startColumn);
    }
    
    advance(); // Skip closing quote
    return Token(TokenType::STRING_LITERAL, value, line, startColumn);
}

Token Lexer::scanNumber() {
    int startColumn = column;
    std::string value;
    
    while (!isAtEnd() && std::isdigit(peek())) {
        value += advance();
    }
    
    // Handle decimal numbers
    if (!isAtEnd() && peek() == '.' && position + 1 < source.length() && 
        std::isdigit(source[position + 1])) {
        value += advance(); // Add the decimal point
        
        while (!isAtEnd() && std::isdigit(peek())) {
            value += advance();
        }
    }
    
    return Token(TokenType::NUMBER, value, line, startColumn);
}

Token Lexer::scanComment() {
    int startColumn = column;
    std::string value;
    
    // Skip the initial //
    advance();
    advance();
    
    // Read until end of line
    while (!isAtEnd() && peek() != '\n') {
        value += advance();
    }
    
    return Token(TokenType::COMMENT, value, line, startColumn);
}

std::vector<Token> Lexer::tokenize() {
    std::vector<Token> tokens;
    
    while (!isAtEnd()) {
        Token token = scanToken();
        // Don't filter out WHITESPACE tokens - they contain important spacing info
        tokens.push_back(token);
    }
    
    tokens.push_back(Token(TokenType::END_OF_FILE, "", line, column));
    return tokens;
}