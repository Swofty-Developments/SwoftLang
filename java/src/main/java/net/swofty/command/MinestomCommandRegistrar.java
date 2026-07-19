package net.swofty.command;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.command.builder.Command;
import net.minestom.server.command.builder.arguments.Argument;
import net.minestom.server.command.builder.arguments.ArgumentBoolean;
import net.minestom.server.command.builder.arguments.ArgumentType;
import net.minestom.server.command.builder.CommandContext;
import net.minestom.server.command.builder.arguments.ArgumentWord;
import net.minestom.server.command.builder.arguments.minecraft.ArgumentEntity;
import net.minestom.server.command.builder.arguments.number.ArgumentDouble;
import net.minestom.server.command.builder.arguments.number.ArgumentInteger;
import net.minestom.server.command.builder.suggestion.SuggestionEntry;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.utils.entity.EntityFinder;
import net.swofty.ASTExecutor;
import net.swofty.async.AsyncRuntime;
import net.swofty.nativebridge.representation.*;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Handles registration of SwoftLang commands with the Minestom command system
 */
public class MinestomCommandRegistrar {
    /**
     * Register a single SwoftLang command with Minestom
     * @param swoftCommand The SwoftLang command to register
     */
    public void registerCommand(net.swofty.nativebridge.representation.Command swoftCommand) {
        // Create a new Minestom command with the name from SwoftLang command
        Command minestomCommand = new Command(swoftCommand.getName());

        // Enforce the declared permission through the pluggable provider
        // (design 6D): the pinned Minestom has no permission API of its
        // own, so the PermissionProvider decides (default allows + logs)
        if (swoftCommand.getPermission() != null && !swoftCommand.getPermission().isEmpty()) {
            String permission = swoftCommand.getPermission();
            minestomCommand.setCondition((sender, commandString) ->
                    net.swofty.permissions.Permissions.check(sender, permission));
        }

        // Set default executor to display usage or error message
        minestomCommand.setDefaultExecutor((sender, context) -> {
            sender.sendMessage("Usage: /" + swoftCommand.getName() + " [arguments]");
        });

        // Check if we have any EITHER types
        boolean hasEitherTypes = false;
        for (Variable arg : swoftCommand.getArguments()) {
            if (arg.getType().getBaseType() == BaseType.EITHER) {
                hasEitherTypes = true;
                break;
            }
        }

        if (hasEitherTypes) {
            // For commands with EITHER types, we need to create multiple syntaxes
            createMultipleSyntaxes(minestomCommand, swoftCommand);
        } else {
            // For commands without EITHER types, create a simple single syntax
            createSingleSyntax(minestomCommand, swoftCommand);
        }

        // Register the command with Minestom
        MinecraftServer.getCommandManager().register(minestomCommand);
        System.out.println("Registered command: " + swoftCommand.getName());
    }

    /**
     * Register multiple SwoftLang commands with Minestom
     * @param swoftCommands Map of SwoftLang commands to register
     */
    public void registerCommands(Map<String, net.swofty.nativebridge.representation.Command> swoftCommands) {
        for (net.swofty.nativebridge.representation.Command command : swoftCommands.values()) {
            registerCommand(command);
        }
    }

    /**
     * Create a single syntax for a command without EITHER types
     */
    private void createSingleSyntax(Command minestomCommand, net.swofty.nativebridge.representation.Command swoftCommand) {
        List<Argument<?>> arguments = new ArrayList<>();

        // Process each argument
        for (Variable arg : swoftCommand.getArguments()) {
            if (arg.getType().getBaseType() == BaseType.LOCATION) {
                // Special handling for location - three arguments
                arguments.add(createDoubleArgument(arg.getName() + "_x", "X coordinate"));
                arguments.add(createDoubleArgument(arg.getName() + "_y", "Y coordinate"));
                arguments.add(createDoubleArgument(arg.getName() + "_z", "Z coordinate"));
            } else {
                // Standard argument
                Argument<?> minestomArg = createStandardArgument(arg);
                if (minestomArg != null) {
                    arguments.add(minestomArg);
                }
            }
        }

        // Add the syntax (carrying the permission condition: the command
        // graph takes the SYNTAX condition for execution, so a bare
        // addSyntax would bypass setCondition on the dispatch path)
        addSyntax(minestomCommand, (sender, context) -> {
            executeCommand(swoftCommand, sender, context);
        }, arguments);
    }

    /**
     * addSyntax that re-attaches the command's permission condition to
     * the syntax itself. In the pinned Minestom command graph a syntax's
     * own condition REPLACES the command-level condition on the
     * execution chain (GraphImpl.ExecutionImpl), so a syntax without one
     * would make /cmd dispatch skip the permission check entirely while
     * tab-complete still hid it.
     */
    private static void addSyntax(Command minestomCommand,
            net.minestom.server.command.builder.CommandExecutor executor,
            List<Argument<?>> arguments) {
        if (minestomCommand.getCondition() != null) {
            minestomCommand.addConditionalSyntax(minestomCommand.getCondition(),
                    executor, arguments.toArray(new Argument[0]));
        } else {
            minestomCommand.addSyntax(executor, arguments.toArray(new Argument[0]));
        }
    }

    /**
     * Create multiple syntaxes for a command with EITHER types
     * This handles all possible combinations of argument types
     */
    private void createMultipleSyntaxes(Command minestomCommand, net.swofty.nativebridge.representation.Command swoftCommand) {
        // First we need to calculate how many syntaxes we need
        List<List<ArgumentVariant>> argumentVariants = new ArrayList<>();

        // For each argument, get its possible variants
        for (Variable arg : swoftCommand.getArguments()) {
            List<ArgumentVariant> variants = getArgumentVariants(arg);
            argumentVariants.add(variants);
        }

        // Generate all possible combinations of argument variants
        List<List<ArgumentVariant>> allCombinations = generateCombinations(argumentVariants);

        // Create a syntax for each combination
        for (List<ArgumentVariant> combination : allCombinations) {
            List<Argument<?>> syntaxArguments = new ArrayList<>();

            // Add all arguments for this combination
            for (ArgumentVariant variant : combination) {
                syntaxArguments.addAll(variant.getArguments());
            }

            // Add the syntax with these arguments (permission-carrying)
            addSyntax(minestomCommand, (sender, context) -> {
                executeCommandWithVariants(swoftCommand, sender, context, combination);
            }, syntaxArguments);
        }
    }

    /**
     * Class to represent a variant of an argument
     */
    private static class ArgumentVariant {
        private final String originalName;
        private final BaseType baseType;
        private final List<Argument<?>> arguments = new ArrayList<>();

        public ArgumentVariant(String originalName, BaseType baseType, Argument<?>... args) {
            this.originalName = originalName;
            this.baseType = baseType;
            for (Argument<?> arg : args) {
                this.arguments.add(arg);
            }
        }

        public String getOriginalName() {
            return originalName;
        }

        public BaseType getBaseType() {
            return baseType;
        }

        public List<Argument<?>> getArguments() {
            return arguments;
        }
    }

    /**
     * Get all possible variants for an argument
     */
    private List<ArgumentVariant> getArgumentVariants(Variable arg) {
        List<ArgumentVariant> variants = new ArrayList<>();

        if (arg.getType().getBaseType() == BaseType.EITHER) {
            // For EITHER type, create a variant for each subtype
            for (DataType subType : arg.getType().getSubTypes()) {
                BaseType subBaseType = subType.getBaseType();

                if (subBaseType == BaseType.PLAYER) {
                    // Player variant
                    ArgumentEntity playerArg = playerArgument(arg.getName());

                    // Set error callback
                    playerArg.setCallback((sender, exception) ->
                            sender.sendMessage("Invalid player: " + exception.getInput()));

                    // Set default value if applicable
                    if (arg.hasDefault()) {
                        setPlayerDefaultValue(playerArg, arg.getDefaultValue());
                    }

                    variants.add(new ArgumentVariant(arg.getName(), BaseType.PLAYER, playerArg));
                } else if (subBaseType == BaseType.LOCATION) {
                    // Location variant (x, y, z)
                    ArgumentDouble xArg = createDoubleArgument(arg.getName() + "_x", "X coordinate");
                    ArgumentDouble yArg = createDoubleArgument(arg.getName() + "_y", "Y coordinate");
                    ArgumentDouble zArg = createDoubleArgument(arg.getName() + "_z", "Z coordinate");

                    variants.add(new ArgumentVariant(arg.getName(), BaseType.LOCATION, xArg, yArg, zArg));
                } else {
                    // Handle other types
                    Argument<?> standardArg = createArgumentForType(arg.getName(), subBaseType);
                    if (standardArg != null) {
                        variants.add(new ArgumentVariant(arg.getName(), subBaseType, standardArg));
                    }
                }
            }
        } else if (arg.getType().getBaseType() == BaseType.LOCATION) {
            // Location (x, y, z)
            ArgumentDouble xArg = createDoubleArgument(arg.getName() + "_x", "X coordinate");
            ArgumentDouble yArg = createDoubleArgument(arg.getName() + "_y", "Y coordinate");
            ArgumentDouble zArg = createDoubleArgument(arg.getName() + "_z", "Z coordinate");

            variants.add(new ArgumentVariant(arg.getName(), BaseType.LOCATION, xArg, yArg, zArg));
        } else {
            // Standard type
            Argument<?> standardArg = createStandardArgument(arg);
            if (standardArg != null) {
                variants.add(new ArgumentVariant(arg.getName(), arg.getType().getBaseType(), standardArg));
            }
        }

        return variants;
    }

    /**
     * Helper method to create a double argument with error handling
     */
    private ArgumentDouble createDoubleArgument(String name, String description) {
        ArgumentDouble arg = ArgumentType.Double(name);
        arg.setCallback((sender, exception) ->
                sender.sendMessage("Invalid " + description + ": " + exception.getInput()));
        return arg;
    }

    /**
     * Create an argument for a specific type
     */
    private Argument<?> createArgumentForType(String name, BaseType type) {
        switch (type) {
            case STRING:
                return ArgumentType.String(name);
            case INTEGER:
                return ArgumentType.Integer(name);
            case DOUBLE:
                return ArgumentType.Double(name);
            case BOOLEAN:
                return ArgumentType.Boolean(name);
            case PLAYER:
                return playerArgument(name);
            default:
                return null;
        }
    }

    /**
     * A player command argument (@a/@p selectors + username), carrying a
     * server-side suggestion callback that lists ONLY real connected players.
     *
     * <p>Without the callback the vanilla client autocompletes an entity /
     * player-selector argument from ITS OWN player list, which includes the
     * fake PlayerInfo tablist entries the UI runtime injects ("tab0", "tab1",
     * ...) — those leaked into {@code /tp <player>} completion. Attaching a
     * suggestion callback flips the node to ASK_SERVER (Argument.
     * setSuggestionCallback sets SuggestionType.ASK_SERVER), so the client
     * asks the server and we answer with getOnlinePlayers usernames only.
     */
    private static ArgumentEntity playerArgument(String name) {
        ArgumentEntity arg = ArgumentType.Entity(name).onlyPlayers(true);
        arg.setSuggestionCallback((sender, context, suggestion) -> {
            for (Player player : MinecraftServer.getConnectionManager().getOnlinePlayers()) {
                suggestion.addEntry(new SuggestionEntry(player.getUsername()));
            }
        });
        return arg;
    }

    /**
     * Generate all possible combinations of argument variants
     */
    private List<List<ArgumentVariant>> generateCombinations(List<List<ArgumentVariant>> argumentVariants) {
        List<List<ArgumentVariant>> result = new ArrayList<>();
        generateCombinationsHelper(argumentVariants, 0, new ArrayList<>(), result);
        return result;
    }

    /**
     * Helper method for generating combinations
     */
    private void generateCombinationsHelper(
            List<List<ArgumentVariant>> argumentVariants,
            int index,
            List<ArgumentVariant> current,
            List<List<ArgumentVariant>> result) {

        if (index == argumentVariants.size()) {
            result.add(new ArrayList<>(current));
            return;
        }

        for (ArgumentVariant variant : argumentVariants.get(index)) {
            current.add(variant);
            generateCombinationsHelper(argumentVariants, index + 1, current, result);
            current.remove(current.size() - 1);
        }
    }

    /**
     * Create a standard argument for a SwoftLang variable
     */
    private Argument<?> createStandardArgument(Variable arg) {
        Argument<?> minestomArg = null;

        // Convert SwoftLang type to Minestom argument type
        switch (arg.getType().getBaseType()) {
            case STRING:
                minestomArg = ArgumentType.String(arg.getName());
                break;
            case INTEGER:
                minestomArg = ArgumentType.Integer(arg.getName());
                break;
            case DOUBLE:
                minestomArg = ArgumentType.Double(arg.getName());
                break;
            case BOOLEAN:
                minestomArg = ArgumentType.Boolean(arg.getName());
                break;
            case PLAYER:
                minestomArg = playerArgument(arg.getName());
                break;
            default:
                return null;
        }

        // Set up argument callback for validation errors
        minestomArg.setCallback((sender, exception) -> {
            sender.sendMessage("Invalid argument '" + exception.getInput() +
                    "' for parameter '" + arg.getName() + "'");
        });

        // If the argument has a default value, try to set it
        if (arg.hasDefault()) {
            try {
                setDefaultValue(minestomArg, arg);
            } catch (Exception e) {
                System.err.println("Could not set default value for argument: " + arg.getName());
            }
        }

        return minestomArg;
    }

    /**
     * Set the default value for an argument if possible
     */
    private void setDefaultValue(Argument<?> minestomArg, Variable arg) {
        String defaultValue = arg.getDefaultValue();
        BaseType type = arg.getType().getBaseType();

        try {
            switch (type) {
                case PLAYER:
                    if (minestomArg instanceof ArgumentEntity) {
                        setPlayerDefaultValue((ArgumentEntity) minestomArg, defaultValue);
                    }
                    break;
                case INTEGER:
                    if (minestomArg instanceof ArgumentInteger) {
                        ((ArgumentInteger) minestomArg)
                                .setDefaultValue(Integer.parseInt(defaultValue));
                    }
                    break;
                case DOUBLE:
                    if (minestomArg instanceof ArgumentDouble) {
                        ((ArgumentDouble) minestomArg)
                                .setDefaultValue(Double.parseDouble(defaultValue));
                    }
                    break;
                case BOOLEAN:
                    if (minestomArg instanceof ArgumentBoolean) {
                        ((ArgumentBoolean) minestomArg)
                                .setDefaultValue(Boolean.parseBoolean(defaultValue));
                    }
                    break;
                case STRING:
                    if (minestomArg instanceof ArgumentWord) {
                        ((ArgumentWord) minestomArg)
                                .setDefaultValue(defaultValue);
                    }
                    break;
            }
        } catch (Exception e) {
            System.err.println("Failed to set default value for " + arg.getName() + ": " + e.getMessage());
        }
    }

    /**
     * Set a player default value based on the string
     */
    private void setPlayerDefaultValue(ArgumentEntity playerArg, String defaultValue) {
        EntityFinder finder = new EntityFinder();

        switch (defaultValue) {
            case "sender":
                finder.setTargetSelector(EntityFinder.TargetSelector.SELF);
                break;
            case "nearest":
                finder.setTargetSelector(EntityFinder.TargetSelector.NEAREST_PLAYER);
                break;
            case "random":
                finder.setTargetSelector(EntityFinder.TargetSelector.RANDOM_PLAYER);
                break;
            case "all":
                finder.setTargetSelector(EntityFinder.TargetSelector.ALL_PLAYERS);
                break;
            default:
                finder.setTargetSelector(EntityFinder.TargetSelector.MINESTOM_USERNAME);
                finder.setConstantName(defaultValue);
                break;
        }

        playerArg.setDefaultValue(finder);
    }

    /**
     * Execute a command with a simple argument structure (no EITHER types)
     */
    private void executeCommand(net.swofty.nativebridge.representation.Command swoftCommand,
                                net.minestom.server.command.CommandSender sender,
                                CommandContext context) {

        Map<String, Object> argValues = new HashMap<>();

        // Process each argument
        for (Variable arg : swoftCommand.getArguments()) {
            BaseType type = arg.getType().getBaseType();

            if (type == BaseType.LOCATION) {
                // Handle location (x, y, z)
                Double x = context.get(arg.getName() + "_x");
                Double y = context.get(arg.getName() + "_y");
                Double z = context.get(arg.getName() + "_z");

                if (x != null && y != null && z != null) {
                    Pos position = new Pos(x, y, z);
                    argValues.put(arg.getName(), position);
                }
            } else {
                // Standard argument
                Object value = context.get(arg.getName());

                // Special handling for player "sender" default
                if (value == null && arg.hasDefault() && arg.getDefaultValue().equals("sender") &&
                        type == BaseType.PLAYER && sender instanceof Player) {

                    value = sender;
                }

                argValues.put(arg.getName(), value);
            }
        }

        // Execute the command using our new architecture
        executeSwoftCommand(swoftCommand, sender, argValues);
    }

    /**
     * Execute a command with argument variants (supports EITHER types)
     */
    private void executeCommandWithVariants(net.swofty.nativebridge.representation.Command swoftCommand,
                                            net.minestom.server.command.CommandSender sender,
                                            CommandContext context,
                                            List<ArgumentVariant> variants) {

        Map<String, Object> argValues = new HashMap<>();

        // Process each argument variant
        for (ArgumentVariant variant : variants) {
            String name = variant.getOriginalName();
            BaseType type = variant.getBaseType();

            if (type == BaseType.LOCATION) {
                // Handle location (x, y, z)
                Double x = context.get(name + "_x");
                Double y = context.get(name + "_y");
                Double z = context.get(name + "_z");

                if (x != null && y != null && z != null) {
                    Pos position = new Pos(x, y, z);
                    argValues.put(name, position);
                }
            } else if (type == BaseType.PLAYER) {
                // Handle player entity
                EntityFinder finder = context.get(name);
                if (finder != null) {
                    Player player = finder.findFirstPlayer(sender);
                    if (player != null) {
                        argValues.put(name, player);
                    }
                }
            } else {
                // Standard argument
                Object value = context.get(name);
                argValues.put(name, value);
            }
        }

        // Execute the command using our new architecture
        executeSwoftCommand(swoftCommand, sender, argValues);
    }

    /**
     * Execute the SwoftLang command using the pre-parsed AST. Async execute
     * blocks detach onto a virtual thread over a snapshot of the argument
     * environment; the command callback returns immediately.
     */
    private void executeSwoftCommand(net.swofty.nativebridge.representation.Command swoftCommand,
                                     net.minestom.server.command.CommandSender minestomSender,
                                     Map<String, Object> argValues) {
        try {
            ExecuteBlock executeBlock = swoftCommand.getExecuteBlock();

            // Adapt the Minestom sender to our CommandSender interface
            CommandSender sender = new MinestomSenderAdapter(minestomSender);

            if (executeBlock.isAsync()) {
                Map<String, Object> snapshot = new HashMap<>(argValues);
                AsyncRuntime.start("command " + swoftCommand.getName(),
                        () -> new ASTExecutor(sender, snapshot).execute(executeBlock));
                return;
            }

            new ASTExecutor(sender, argValues).execute(executeBlock);

        } catch (Exception e) {
            minestomSender.sendMessage("Error executing command: " + e.getMessage());
            e.printStackTrace();
        }
    }
}