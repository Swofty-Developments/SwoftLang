package net.swofty.command;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.swofty.command.executors.CommandExecutor;
import net.swofty.command.executors.SendCommandExecutor;
import net.swofty.command.executors.TeleportCommandExecutor;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Execution context for script interpretation
 */
public class ExecutionContext {
    private final CommandSender sender;
    private final Map<String, Object> arguments;
    private final Map<String, Object> variables = new HashMap<>();
    private final Map<String, CommandExecutor> commandExecutors = new HashMap<>();
    private boolean halted = false;

    public ExecutionContext(CommandSender sender, Map<String, Object> arguments) {
        this.sender = sender;
        this.arguments = arguments;

        // Register standard command executors
        registerCommandExecutor(new SendCommandExecutor());
        registerCommandExecutor(new TeleportCommandExecutor());
    }

    /**
     * Register a command executor
     */
    public void registerCommandExecutor(CommandExecutor executor) {
        commandExecutors.put(executor.getCommandName(), executor);
    }

    /**
     * Get a command executor by name
     */
    public CommandExecutor getCommandExecutor(String commandName) {
        return commandExecutors.get(commandName);
    }

    /**
     * Get a variable value
     */
    public Object getVariable(String name) {
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

        // Try to parse as literal
        return parseAny(name);
    }

    /**
     * Set a variable value
     */
    public void setVariable(String name, Object value) {
        variables.put(name, value);
    }

    /**
     * Check if execution is halted
     */
    public boolean isHalted() {
        return halted;
    }

    /**
     * Halt execution
     */
    public void halt() {
        halted = true;
    }

    /**
     * Interpolate variables in a string
     */
    public String interpolateString(String text) {
        Pattern pattern = Pattern.compile("\\$\\{([^}]+)\\}");
        Matcher matcher = pattern.matcher(text);
        StringBuffer result = new StringBuffer();

        while (matcher.find()) {
            String varName = matcher.group(1);
            Object value = getVariable(varName);
            String replacement = value != null ? value.toString() : "null";
            replacement = replacement.replace("\\", "\\\\").replace("$", "\\$");
            matcher.appendReplacement(result, replacement);
        }
        matcher.appendTail(result);

        return formatColorCodes(result.toString());
    }

    /**
     * Format color codes in a string
     */
    public String formatColorCodes(String text) {
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

    /**
     * Execute a send command
     */
    public void send(String message, Object target) {
        if (target == null || target.equals("sender")) {
            sender.sendMessage(message);
        } else if (target.equals("all")) {
            // Send to all players - would need to implement with MinecraftServer
            sender.sendMessage("[To All] " + message);
        } else if (target instanceof Player) {
            ((Player) target).sendMessage(message);
        } else {
            throw new RuntimeException("Invalid target for send command: " + target);
        }
    }

    /**
     * Execute a teleport command
     */
    public void teleport(Object entity, Object target) {
        if (!(entity instanceof Player)) {
            throw new RuntimeException("Can only teleport players");
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
            throw new RuntimeException("Invalid teleport target: " + target);
        }
    }

    /**
     * Evaluate a condition
     */
    public boolean evaluateCondition(Object left, String operator, Object right) {
        if (operator.equals("is")) {
            // Type check
            return checkType(left, right);
        } else if (operator.equals("is not")) {
            // Negated type check
            return !checkType(left, right);
        }

        // Comparison operators
        return compareValues(left, right, operator);
    }

    /**
     * Check if an object is of a certain type
     */
    private boolean checkType(Object object, Object typeName) {
        if (!(typeName instanceof String)) {
            throw new RuntimeException("Type name must be a string");
        }

        String type = (String) typeName;
        switch (type) {
            case "Player":
                return object instanceof Player;
            case "Location":
                return object instanceof Pos;
            case "String":
                return object instanceof String;
            case "Number":
                return object instanceof Number;
            case "Boolean":
                return object instanceof Boolean;
            default:
                throw new RuntimeException("Unknown type: " + type);
        }
    }

    /**
     * Compare two values with an operator
     */
    private boolean compareValues(Object left, Object right, String operator) {
        if (left == null || right == null) {
            return operator.equals("==") ? (left == right) : (left != right);
        }

        // String comparison
        if (left instanceof String || right instanceof String) {
            String leftStr = String.valueOf(left);
            String rightStr = String.valueOf(right);

            switch (operator) {
                case "==": return leftStr.equals(rightStr);
                case "!=": return !leftStr.equals(rightStr);
                default:
                    throw new RuntimeException("Invalid operator for strings: " + operator);
            }
        }

        // Numeric comparison
        if (left instanceof Number && right instanceof Number) {
            double leftNum = ((Number) left).doubleValue();
            double rightNum = ((Number) right).doubleValue();

            switch (operator) {
                case "==": return leftNum == rightNum;
                case "!=": return leftNum != rightNum;
                case ">": return leftNum > rightNum;
                case "<": return leftNum < rightNum;
                case ">=": return leftNum >= rightNum;
                case "<=": return leftNum <= rightNum;
                default:
                    throw new RuntimeException("Invalid operator: " + operator);
            }
        }

        // Default to equality check
        return operator.equals("==") ? left.equals(right) : !left.equals(right);
    }

    /**
     * Parse any value from string
     */
    private Object parseAny(String value) {
        // Try to parse as boolean
        if (value.equals("true")) return true;
        if (value.equals("false")) return false;

        // Try to parse as number
        try {
            if (value.contains(".")) {
                return Double.parseDouble(value);
            } else {
                return Integer.parseInt(value);
            }
        } catch (NumberFormatException e) {
            // Not a number, return as string
            return value;
        }
    }
}