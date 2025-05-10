package net.swofty.command;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.swofty.execution.BlockStatement;
import net.swofty.execution.Expression;
import net.swofty.execution.Statement;
import net.swofty.execution.commands.*;
import net.swofty.execution.expressions.BinaryExpression;
import net.swofty.execution.expressions.StringLiteral;
import net.swofty.execution.expressions.TypeLiteral;
import net.swofty.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.ExecuteBlock;

import java.util.HashMap;
import java.util.Map;

/**
 * Executes pre-parsed SwoftLang AST directly
 */
public class ASTExecutor {
    private final CommandSender sender;
    private final Map<String, Object> arguments;
    private final Map<String, Object> variables = new HashMap<>();
    private boolean halted = false;

    public ASTExecutor(CommandSender sender, Map<String, Object> arguments) {
        this.sender = sender;
        this.arguments = arguments;
    }

    /**
     * Execute an execute block
     */
    public void execute(ExecuteBlock block) {
        for (Statement statement : block.getStatements()) {
            if (halted) {
                break;
            }
            executeStatement(statement);
        }
    }

    /**
     * Execute a single statement
     */
    private void executeStatement(Statement statement) {
        if (statement instanceof SendCommand) {
            executeSendCommand((SendCommand) statement);
        } else if (statement instanceof TeleportCommand) {
            executeTeleportCommand((TeleportCommand) statement);
        } else if (statement instanceof HaltCommand) {
            halted = true;
        } else if (statement instanceof IfStatement) {
            executeIfStatement((IfStatement) statement);
        } else if (statement instanceof BlockStatement) {
            executeBlockStatement((BlockStatement) statement);
        } else if (statement instanceof VariableAssignment) {
            executeVariableAssignment((VariableAssignment) statement);
        }
    }

    /**
     * Execute a send command
     */
    private void executeSendCommand(SendCommand command) {
        String message = evaluateStringExpression(command.getMessage());
        Object target = command.getTarget() != null ? evaluateExpression(command.getTarget()) : sender;

        // Format color codes
        message = formatColorCodes(message);

        if (target == null || target.equals("sender")) {
            sender.sendMessage(message);
        } else if (target.equals("all")) {
            // Send to all players
            sender.sendMessage("[To All] " + message);
        } else if (target instanceof Player) {
            ((Player) target).sendMessage(message);
        } else {
            sender.sendMessage("Error: Cannot send message to " + target);
        }
    }

    /**
     * Execute a teleport command
     */
    private void executeTeleportCommand(TeleportCommand command) {
        Object entity = evaluateExpression(command.getEntity());
        Object target = evaluateExpression(command.getTarget());

        if (!(entity instanceof Player)) {
            sender.sendMessage("Error: Cannot teleport non-player entity");
            return;
        }

        Player player = (Player) entity;

        if (target instanceof Player) {
            // Teleport to player
            Player targetPlayer = (Player) target;
            player.teleport(targetPlayer.getPosition());

            if (player != sender && sender instanceof Player) {
                sender.sendMessage("Teleported " + player.getUsername() + " to " + targetPlayer.getUsername());
            }
        } else if (target instanceof Pos) {
            // Teleport to location
            Pos position = (Pos) target;
            player.teleport(position);

            if (player != sender && sender instanceof Player) {
                sender.sendMessage("Teleported " + player.getUsername() + " to " +
                        String.format("%.2f, %.2f, %.2f", position.x(), position.y(), position.z()));
            }
        } else {
            sender.sendMessage("Error: Cannot teleport to " + target + " - not a player or location");
        }
    }

    /**
     * Execute an if statement
     */
    private void executeIfStatement(IfStatement statement) {
        boolean conditionResult = evaluateBooleanExpression(statement.getCondition());

        if (conditionResult) {
            executeStatement(statement.getThenStatement());
        } else if (statement.getElseStatement() != null) {
            executeStatement(statement.getElseStatement());
        }
    }

    /**
     * Execute a block statement
     */
    private void executeBlockStatement(BlockStatement statement) {
        for (Statement stmt : statement.getStatements()) {
            if (halted) {
                break;
            }
            executeStatement(stmt);
        }
    }

    /**
     * Execute a variable assignment
     */
    private void executeVariableAssignment(VariableAssignment assignment) {
        String variableName = assignment.getVariableName();
        Object value = evaluateExpression(assignment.getValue());
        variables.put(variableName, value);
    }

    /**
     * Evaluate an expression and get its value
     */
    private Object evaluateExpression(Expression expression) {
        if (expression instanceof StringLiteral) {
            String value = ((StringLiteral) expression).getValue();
            return interpolateString(value);
        } else if (expression instanceof VariableReference) {
            String name = ((VariableReference) expression).getName();
            return getVariable(name);
        } else if (expression instanceof BinaryExpression) {
            return evaluateBinaryExpression((BinaryExpression) expression);
        } else if (expression instanceof TypeLiteral) {
            return ((TypeLiteral) expression).getTypeName();
        }

        throw new RuntimeException("Unknown expression type: " + expression.getClass().getSimpleName());
    }

    /**
     * Evaluate a binary expression
     */
    private Object evaluateBinaryExpression(BinaryExpression expression) {
        Object left = evaluateExpression(expression.getLeft());
        Object right = evaluateExpression(expression.getRight());
        BinaryExpression.Operator operator = expression.getOperator();

        switch (operator) {
            case EQUALS:
                return objectsEqual(left, right);
            case NOT_EQUALS:
                return !objectsEqual(left, right);
            case LESS_THAN:
                return compareObjects(left, right) < 0;
            case GREATER_THAN:
                return compareObjects(left, right) > 0;
            case LESS_EQUALS:
                return compareObjects(left, right) <= 0;
            case GREATER_EQUALS:
                return compareObjects(left, right) >= 0;
            case AND:
                return toBoolean(left) && toBoolean(right);
            case OR:
                return toBoolean(left) || toBoolean(right);
            case IS_TYPE:
                return isType(left, (String) right);
            case IS_NOT_TYPE:
                return !isType(left, (String) right);
            default:
                throw new RuntimeException("Unknown operator: " + operator);
        }
    }

    /**
     * Get a variable value
     */
    private Object getVariable(String name) {
        if (name.equals("sender")) {
            return sender;
        }

        if (name.startsWith("args.")) {
            String argName = name.substring(5);
            return arguments.get(argName);
        }

        if (variables.containsKey(name)) {
            return variables.get(name);
        }

        return name; // Return as literal string if not found
    }

    /**
     * Interpolate variables in a string
     */
    private String interpolateString(String text) {
        // Simple variable interpolation
        StringBuilder result = new StringBuilder();
        int i = 0;

        while (i < text.length()) {
            if (text.charAt(i) == '$' && i + 1 < text.length() && text.charAt(i + 1) == '{') {
                // Find the closing brace
                int closeIndex = text.indexOf('}', i + 2);
                if (closeIndex != -1) {
                    String varName = text.substring(i + 2, closeIndex);
                    Object value = getVariable(varName);
                    result.append(value != null ? value.toString() : "");
                    i = closeIndex + 1;
                    continue;
                }
            }
            result.append(text.charAt(i));
            i++;
        }

        return result.toString();
    }

    /**
     * Evaluate an expression as a string
     */
    private String evaluateStringExpression(Expression expression) {
        Object value = evaluateExpression(expression);
        return value != null ? value.toString() : "";
    }

    /**
     * Evaluate an expression as a boolean
     */
    private boolean evaluateBooleanExpression(Expression expression) {
        Object value = evaluateExpression(expression);
        return toBoolean(value);
    }

    /**
     * Convert an object to a boolean
     */
    private boolean toBoolean(Object obj) {
        if (obj instanceof Boolean) {
            return (Boolean) obj;
        }
        if (obj instanceof Number) {
            return ((Number) obj).doubleValue() != 0;
        }
        if (obj instanceof String) {
            return !((String) obj).isEmpty();
        }
        return obj != null;
    }

    /**
     * Check if two objects are equal
     */
    private boolean objectsEqual(Object left, Object right) {
        if (left == null && right == null) return true;
        if (left == null || right == null) return false;

        // Handle numeric comparison
        if (left instanceof Number && right instanceof Number) {
            return ((Number) left).doubleValue() == ((Number) right).doubleValue();
        }

        return left.equals(right);
    }

    /**
     * Compare two objects
     */
    private int compareObjects(Object left, Object right) {
        if (left instanceof Number && right instanceof Number) {
            double l = ((Number) left).doubleValue();
            double r = ((Number) right).doubleValue();
            return Double.compare(l, r);
        }

        if (left instanceof String && right instanceof String) {
            return ((String) left).compareTo((String) right);
        }

        throw new RuntimeException("Cannot compare objects of types: " +
                left.getClass().getSimpleName() + " and " + right.getClass().getSimpleName());
    }

    /**
     * Check if an object is of a certain type
     */
    private boolean isType(Object obj, String typeName) {
        switch (typeName) {
            case "Player":
                return obj instanceof Player;
            case "Location":
                return obj instanceof Pos;
            case "String":
                return obj instanceof String;
            case "Number":
                return obj instanceof Number;
            case "Boolean":
                return obj instanceof Boolean;
            default:
                return false;
        }
    }

    /**
     * Format color codes in a string
     */
    private String formatColorCodes(String text) {
        return text.replace("<red>", "§c")
                .replace("<green>", "§a")
                .replace("<lime>", "§a")
                .replace("<blue>", "§9")
                .replace("<yellow>", "§e")
                .replace("<gold>", "§6")
                .replace("<white>", "§f")
                .replace("<black>", "§0")
                .replace("<reset>", "§r");
    }
}