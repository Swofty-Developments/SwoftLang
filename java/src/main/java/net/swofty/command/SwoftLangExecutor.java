package net.swofty.command;

import net.minestom.server.command.CommandSender;
import net.swofty.ast.SwoftInterpreter;
import net.swofty.lexer.SwoftLexer;
import net.swofty.lexer.Token;
import net.swofty.nativebridge.representation.CodeBlock;
import net.swofty.parser.SwoftParser;

import java.util.List;
import java.util.Map;

/**
 * Executes SwoftLang code blocks within Minestom using the proper lexer/parser/interpreter architecture
 */
public class SwoftLangExecutor {
    private final CommandSender sender;
    private final Map<String, Object> arguments;
    private final String code;

    /**
     * Create a new executor for a code block
     * @param codeBlock The SwoftLang code block to execute
     * @param sender The command sender
     * @param arguments The command arguments
     */
    public SwoftLangExecutor(CodeBlock codeBlock, CommandSender sender, Map<String, Object> arguments) {
        this.code = codeBlock.getCode();
        this.sender = sender;
        this.arguments = arguments;
    }

    /**
     * Execute the code block
     */
    public void execute() {
        try {
            // Debug: Log the code being executed
            System.out.println("=== Executing SwoftLang code ===");
            System.out.println("Code to execute (raw):");
            System.out.println("Length: " + code.length());
            System.out.println("Escaped representation:");

            // Show escaped representation of the code
            StringBuilder escaped = new StringBuilder();
            for (int i = 0; i < code.length(); i++) {
                char c = code.charAt(i);
                if (c == '\n') {
                    escaped.append("\\n");
                } else if (c == '\r') {
                    escaped.append("\\r");
                } else if (c == '\t') {
                    escaped.append("\\t");
                } else if (c == ' ') {
                    escaped.append("·"); // Use a visible character for spaces
                } else {
                    escaped.append(c);
                }
            }
            System.out.println("'" + escaped.toString() + "'");

            System.out.println("Human-readable:");
            System.out.println("---");
            System.out.println(code);
            System.out.println("---");

            System.out.println("Arguments provided:");
            for (Map.Entry<String, Object> entry : arguments.entrySet()) {
                System.out.println("  " + entry.getKey() + " = " + entry.getValue());
            }

            // Lex the code
            System.out.println("\n=== Lexing stage ===");
            SwoftLexer lexer = new SwoftLexer(code);
            List<Token> tokens = lexer.tokenize();

            // Debug: Log all tokens
            System.out.println("Tokens produced:");
            for (int i = 0; i < tokens.size(); i++) {
                Token token = tokens.get(i);
                System.out.println("  [" + i + "] " + token);
            }

            // Parse the tokens into an AST
            System.out.println("\n=== Parsing stage ===");
            SwoftParser parser = new SwoftParser(tokens);
            net.swofty.ast.nodes.Program program = parser.parse();

            System.out.println("Parsing completed successfully");

            // Create execution context
            ExecutionContext context = new ExecutionContext(sender, arguments);

            // Interpret the program
            System.out.println("\n=== Interpretation stage ===");
            SwoftInterpreter interpreter = new SwoftInterpreter(context);
            interpreter.interpret(program);

            System.out.println("Execution completed");

        } catch (SwoftParser.ParseException e) {
            List<Token> tokens = new SwoftLexer(code).tokenize();
            Token problemToken = e.getPosition() < tokens.size() ? tokens.get(e.getPosition()) : null;

            String detailedError = String.format(
                    "Parse error at position %d: %s\n" +
                            "Problem token: %s\n" +
                            "Near: %s",
                    e.getPosition(),
                    e.getMessage(),
                    problemToken != null ? problemToken.toString() : "EOF",
                    getContextAroundError(code, problemToken)
            );

            System.err.println("=== PARSE ERROR ===");
            System.err.println(detailedError);

            sender.sendMessage("Parse error: " + e.getMessage());
            sender.sendMessage("Check the console for detailed error information");

        } catch (Exception e) {
            System.err.println("=== EXECUTION ERROR ===");
            System.err.println("Error type: " + e.getClass().getSimpleName());
            System.err.println("Error message: " + e.getMessage());
            System.err.println("Stack trace:");
            e.printStackTrace();

            sender.sendMessage("Script execution error: " + e.getMessage());
            sender.sendMessage("Check the console for detailed error information");
        }
    }

    private String getContextAroundError(String code, Token problemToken) {
        if (problemToken == null) {
            return "End of input";
        }

        String[] lines = code.split("\n");
        int line = problemToken.getLine() - 1; // Convert to 0-based index
        int column = problemToken.getColumn() - 1; // Convert to 0-based index

        if (line < 0 || line >= lines.length) {
            return "Invalid position";
        }

        String lineContent = lines[line];
        StringBuilder context = new StringBuilder();

        // Show the problematic line
        context.append("Line ").append(problemToken.getLine()).append(": ").append(lineContent);
        context.append("\n");

        // Add a pointer to the problematic column
        context.append("        "); // Indent to match "Line X: "
        for (int i = 0; i < column; i++) {
            context.append(" ");
        }
        context.append("^");

        return context.toString();
    }
}