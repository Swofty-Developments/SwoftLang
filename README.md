# SwoftLang

[<img src="https://discordapp.com/assets/e4923594e694a21542a489471ecffa50.svg" alt="" height="55" />](https://discord.gg/paper)

A powerful scripting language for creating Minecraft servers, built on the Minestom library. SwoftLang combines the flexibility of a scripting language with the performance benefits of C++ and Java interoperability, making it ideal for developing custom Minecraft server experiences.

## Overview

SwoftLang is a dedicated scripting language designed specifically for Minecraft server development. It leverages both Java and C++ through JNI, allowing server developers to write efficient code that interacts seamlessly with the Minestom ecosystem. This approach provides the ease of use of a scripting language while maintaining high performance for server operations.

#### Releases

Releases are auto deployed on push onto the GitHub releases page which can be found [here](#). Updates are also periodically sent within my discord server located at [discord.gg/paper](https://discord.gg/paper).

### How SwoftLang Works

1. **C++ Parser Layer**
   - **Lexical Analysis**: C++ code tokenizes SwoftLang script files (`.sw` files) using a custom lexer
   - **Parsing**: Tokens are parsed into an Abstract Syntax Tree (AST) representing commands, variables, control flow, and expressions
   - **Type Checking**: Variable types and command arguments are validated during the parsing phase

2. **JNI Bridge Layer**
   - Parsed C++ objects are converted to Java representations via JNI
   - Each C++ AST node has a corresponding Java class in the `nativebridge.representation` and `nativebridge.execution` packages
   - Commands, expressions, and statements are serialized across the language boundary

3. **Java Execution Layer**
   - Executes block statements that can manipulate game state, send messages, teleport players, etc.

### Performance Benefits

- **Parse-time Optimization**: Complex parsing logic runs in optimized C++
- **Runtime Efficiency**: Java objects are pre-validated and structured for fast execution
- **Memory Management**: JNI handles object lifecycle across language boundaries

## Credits

Thanks to:
* The contributors to this project, which can be viewed on this Git page.