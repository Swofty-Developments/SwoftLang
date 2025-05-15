package net.swofty;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.item.ItemStack;
import net.swofty.mapper.PropertyMapperInitializer;
import net.swofty.mapper.PropertyMapperRegistry;
import net.swofty.nativebridge.execution.BlockStatement;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.nativebridge.execution.commands.CancelEventStatement;
import net.swofty.nativebridge.execution.commands.HaltCommand;
import net.swofty.nativebridge.execution.commands.IfStatement;
import net.swofty.nativebridge.execution.commands.SendCommand;
import net.swofty.nativebridge.execution.commands.TeleportCommand;
import net.swofty.nativebridge.execution.commands.VariableAssignment;
import net.swofty.nativebridge.execution.expressions.BinaryExpression;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.execution.expressions.TypeLiteral;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * Executes pre-parsed SwoftLang AST directly with enhanced property resolution
 */
public class ASTExecutor {
    private final CommandSender sender;
    private final Map<String, Object> variables;
    private boolean halted = false;

    // Static initializer to ensure property mappers are initialized
    static {
        // Initialize property mappers
        PropertyMapperInitializer.initialize();
    }

    public ASTExecutor(CommandSender sender, Map<String, Object> variables) {
        this.sender = sender;
        this.variables = variables != null ? variables : new HashMap<>();
        
        // Add sender to variables if not already present
        if (!this.variables.containsKey("sender")) {
            this.variables.put("sender", sender);
        }
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
    protected void executeStatement(Statement statement) {
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
        } else if (statement instanceof CancelEventStatement) {
            executeCancelEventStatement();
        }
    }

    /**
     * Execute a cancel event statement
     */
    protected void executeCancelEventStatement() {
        // Get the event object
        Object event = getVariable("event");
        if (event == null) {
            System.err.println("Error: Cannot cancel event - no event object found");
            return;
        }

        // Try to call cancel method on the event object
        try {
            Method cancelMethod = event.getClass().getMethod("cancel");
            cancelMethod.invoke(event);
        } catch (Exception e) {
            System.err.println("Error: Cannot cancel event - " + e.getMessage());
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

        if (target == null || target == sender || target.equals("sender")) {
            sender.sendMessage(message);
        } else if (target.equals("all")) {
            // Send to all players
            for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                player.sendMessage(message);
            }
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
        
        // Check if this is a property assignment (contains a dot)
        if (variableName.contains(".")) {
            String[] parts = variableName.split("\\.", 2);
            String objName = parts[0];
            String propPath = parts[1];
            
            Object obj = getVariable(objName);
            if (obj != null) {
                setNestedProperty(obj, propPath, value);
            } else {
                System.err.println("Error: Cannot set property on non-existent object: " + objName);
            }
        } else {
            // Simple variable assignment
            variables.put(variableName, value);
        }
    }

    /**
     * Evaluate an expression and get its value
     */
    protected Object evaluateExpression(Expression expression) {
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
    protected Object evaluateBinaryExpression(BinaryExpression expression) {
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
            case CONTAINS:
            {
                // Debug logging to inspect operands
                System.out.println("CONTAINS check - Left: '" + left + "' (" +
                        (left != null ? left.getClass().getName() : "null") +
                        "), Right: '" + right + "' (" +
                        (right != null ? right.getClass().getName() : "null") + ")");

                // Convert both operands to lowercase strings for case-insensitive comparison
                String leftStr = left != null ? getDisplayString(left).toLowerCase() : "";
                String rightStr = right != null ? getDisplayString(right).toLowerCase() : "";

                // Check if leftStr contains rightStr
                boolean result = leftStr.contains(rightStr);
                System.out.println("CONTAINS result: " + result + " (checking if '" +
                        leftStr + "' contains '" + rightStr + "')");
                return result;
            }
            
            case CONCATENATE:
                {
                    // Convert both operands to strings and concatenate
                    String leftStr = left != null ? getDisplayString(left) : "null";
                    String rightStr = right != null ? getDisplayString(right) : "null";
                    return leftStr + rightStr;
                }
            default:
                throw new RuntimeException("Unknown operator: " + operator);
        }
    }

    /**
     * Get a variable value with property path resolution
     * Handles paths like "event.player.name"
     */
    protected Object getVariable(String path) {
        // Split the path into parts
        String[] parts = path.split("\\.");
        
        // Get the root object
        Object current = variables.get(parts[0]);
        if (current == null) {
            // Special case for "args" prefix
            if (parts[0].equals("args") && parts.length > 1) {
                return variables.get(parts[1]);
            }
            return null;
        }
        
        // Navigate the property path
        for (int i = 1; i < parts.length; i++) {
            String prop = parts[i];
            current = getObjectProperty(current, prop);
            
            if (current == null) {
                return null; // Property not found
            }
        }
        
        return current;
    }

    /**
     * Get a property value from an object
     * Uses the PropertyMapperRegistry first, then falls back to reflection
     */
    protected Object getObjectProperty(Object obj, String property) {
        if (obj == null) {
            return null;
        }

        // Try the property mapper registry first
        Object value = PropertyMapperRegistry.getProperty(obj, property);
        if (value != null) {
            return value;
        }

        // Fall back to reflection
        try {
            // Try to find a getter method first
            String getterName = "get" + Character.toUpperCase(property.charAt(0)) + property.substring(1);
            Method getter = null;
            
            try {
                getter = obj.getClass().getMethod(getterName);
            } catch (NoSuchMethodException e) {
                // Try alternative getter for boolean properties
                if (property.length() > 2 && property.startsWith("is")) {
                    try {
                        getter = obj.getClass().getMethod(property);
                    } catch (NoSuchMethodException e2) {
                        // No getter found
                    }
                }
            }
            
            if (getter != null) {
                return getter.invoke(obj);
            }
            
            // If no getter, try direct field access
            try {
                Field field = obj.getClass().getField(property);
                return field.get(obj);
            } catch (NoSuchFieldException e) {
                // No public field found
            }
            
            // Try declared fields (including private ones)
            Field field = obj.getClass().getDeclaredField(property);
            field.setAccessible(true);
            return field.get(obj);
            
        } catch (Exception e) {
            // Debug log when a property is not found
            System.out.println("Error accessing property '" + property + "' on object of type " + 
                              obj.getClass().getName() + ": " + e.getMessage());
            return null;
        }
    }

    /**
     * Set a property on an object, handling nested properties
     */
    protected void setNestedProperty(Object obj, String propertyPath, Object value) {
        if (obj == null) {
            return;
        }
        
        // Handle nested properties
        if (propertyPath.contains(".")) {
            String[] parts = propertyPath.split("\\.", 2);
            String firstProp = parts[0];
            String restProps = parts[1];
            
            Object subObj = getObjectProperty(obj, firstProp);
            if (subObj != null) {
                setNestedProperty(subObj, restProps, value);
            }
        } else {
            // Set the property directly
            setObjectProperty(obj, propertyPath, value);
        }
    }

    /**
     * Set a property value on an object
     * Uses the PropertyMapperRegistry first, then falls back to reflection
     */
    protected void setObjectProperty(Object obj, String property, Object value) {
        if (obj == null) {
            return;
        }

        // Try the property mapper registry first
        if (PropertyMapperRegistry.setProperty(obj, property, value)) {
            return;
        }

        // Fall back to reflection
        try {
            // Try to find a setter method first
            String setterName = "set" + Character.toUpperCase(property.charAt(0)) + property.substring(1);
            
            // Find all methods that match the setter name
            for (Method method : obj.getClass().getMethods()) {
                if (method.getName().equals(setterName) && method.getParameterCount() == 1) {
                    // Convert the value to the expected type if needed
                    Class<?> paramType = method.getParameterTypes()[0];
                    Object convertedValue = convertValue(value, paramType);
                    
                    if (convertedValue != null || paramType.isPrimitive()) {
                        method.invoke(obj, convertedValue);
                        return;
                    }
                }
            }
            
            // If no setter, try direct field access
            try {
                Field field = obj.getClass().getField(property);
                Class<?> fieldType = field.getType();
                Object convertedValue = convertValue(value, fieldType);
                field.set(obj, convertedValue);
                return;
            } catch (NoSuchFieldException e) {
                // No public field found
            }
            
            // Try declared fields (including private ones)
            Field field = obj.getClass().getDeclaredField(property);
            field.setAccessible(true);
            Class<?> fieldType = field.getType();
            Object convertedValue = convertValue(value, fieldType);
            field.set(obj, convertedValue);
            
        } catch (Exception e) {
            System.err.println("Error setting property '" + property + "' on object of type " + 
                              obj.getClass().getName() + ": " + e.getMessage());
        }
    }

    /**
     * Convert a value to the specified type if possible
     */
    private Object convertValue(Object value, Class<?> targetType) {
        if (value == null) {
            return null;
        }
        
        // If the value is already of the correct type
        if (targetType.isAssignableFrom(value.getClass())) {
            return value;
        }
        
        // String conversion
        if (targetType == String.class) {
            return getDisplayString(value);
        }
        
        // Primitive type conversions
        if (value instanceof String) {
            String strValue = (String) value;
            
            if (targetType == int.class || targetType == Integer.class) {
                try {
                    return Integer.parseInt(strValue);
                } catch (NumberFormatException e) {
                    return 0;
                }
            }
            
            if (targetType == double.class || targetType == Double.class) {
                try {
                    return Double.parseDouble(strValue);
                } catch (NumberFormatException e) {
                    return 0.0;
                }
            }
            
            if (targetType == boolean.class || targetType == Boolean.class) {
                return Boolean.parseBoolean(strValue);
            }
        }
        
        // Number conversions
        if (value instanceof Number) {
            Number numValue = (Number) value;
            
            if (targetType == int.class || targetType == Integer.class) {
                return numValue.intValue();
            }
            
            if (targetType == double.class || targetType == Double.class) {
                return numValue.doubleValue();
            }
            
            if (targetType == boolean.class || targetType == Boolean.class) {
                return numValue.doubleValue() != 0;
            }
        }
        
        // Boolean conversions
        if (value instanceof Boolean) {
            Boolean boolValue = (Boolean) value;
            
            if (targetType == int.class || targetType == Integer.class) {
                return boolValue ? 1 : 0;
            }
            
            if (targetType == double.class || targetType == Double.class) {
                return boolValue ? 1.0 : 0.0;
            }
            
            if (targetType == String.class) {
                return boolValue.toString();
            }
        }
        
        // Can't convert
        return null;
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
                    result.append(value != null ? getDisplayString(value) : "");
                    i = closeIndex + 1;
                    continue;
                }
            }
            result.append(text.charAt(i));
            i++;
        }

        return result.toString();
    }

    protected String getDisplayString(Object value) {
        if (value instanceof Player) {
            return ((Player) value).getUsername();
        } else if (value instanceof Pos) {
            Pos loc = (Pos) value;
            return String.format("x=%.1f, y=%.1f, z=%.1f", loc.x(), loc.y(), loc.z());
        } else if (value instanceof ItemStack) {
            ItemStack item = (ItemStack) value;
            return item.material().name() + " x" + item.amount();
        } else if (value != null) {
            return value.toString();
        } else {
            return "null";
        }
    }

    /**
     * Evaluate an expression as a string
     */
    protected String evaluateStringExpression(Expression expression) {
        Object value = evaluateExpression(expression);
        return value != null ? value.toString() : "";
    }

    /**
     * Evaluate an expression as a boolean
     */
    protected boolean evaluateBooleanExpression(Expression expression) {
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

    protected void halt() {
        this.halted = true;
    }

    protected CommandSender getSender() {
        return sender;
    }

    protected Map<String, Object> getVariables() {
        return variables;
    }
}