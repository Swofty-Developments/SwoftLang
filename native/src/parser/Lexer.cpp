#include "Lexer.h"
#include <cctype>
#include <unordered_map>

// Keywords map
static const std::unordered_map<std::string, TokenType> KEYWORDS = {
    {"command", TokenType::COMMAND},
    {"event", TokenType::EVENT},
    {"if", TokenType::IF},
    {"else", TokenType::ELSE},
    {"halt", TokenType::HALT},
    {"send", TokenType::SEND},
    {"teleport", TokenType::TELEPORT},
    {"to", TokenType::TO},
    {"is", TokenType::IS},
    {"not", TokenType::NOT},
    {"either", TokenType::EITHER},
    {"cancel", TokenType::CANCEL},
    {"set", TokenType::SET},
    {"contains", TokenType::CONTAINS}
};

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
    
    // Check for comments FIRST
    if (c == '/' && position + 1 < source.length() && source[position + 1] == '/') {
        return scanComment();
    }
    
    if (std::isalpha(c) || c == '_') {
        return scanIdentifier();
    }
    
    if (std::isdigit(c)) {
        return scanNumber();
    }
    
    switch (c) {
        case '"': return scanString();
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
        case '.':
            advance();
            return Token(TokenType::DOT, ".", line, column - 1);
        case '+':
            advance();
            return Token(TokenType::PLUS, "+", line, column - 1);
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
    
    // Check if it's a keyword
    auto it = KEYWORDS.find(value);
    if (it != KEYWORDS.end()) {
        return Token(it->second, value, line, startColumn);
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
    
    // Read until end of line OR end of file
    while (!isAtEnd() && peek() != '\n') {
        value += advance();
    }
    
    // Don't advance past the newline - let skipWhitespace handle it
    return Token(TokenType::COMMENT, value, line, startColumn);
}

std::vector<Token> Lexer::tokenize() {
    std::vector<Token> tokens;
    
    while (!isAtEnd()) {
        Token token = scanToken();
        // Skip comments AND whitespace tokens
        if (token.type != TokenType::WHITESPACE && token.type != TokenType::COMMENT) {
            tokens.push_back(token);
        }
    }
    
    tokens.push_back(Token(TokenType::END_OF_FILE, "", line, column));
    return tokens;
}