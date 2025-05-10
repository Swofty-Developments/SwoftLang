package net.swofty.nativebridge;

import net.swofty.nativebridge.representation.Command;
import net.swofty.nativebridge.representation.ExecuteBlock;

public class NativeParser {
    /**
     * Parse SwoftLang code and return a JSON representation.
     * @param code The SwoftLang code to parse
     * @return A JSON string representing the parsed commands
     */
    public static native String parseSwoftLang(String code);
    
    /**
     * Parse SwoftLang code and return an array of Command objects.
     * @param code The SwoftLang code to parse
     * @return An array of Command objects
     */
    public static native Command[] parseSwoftLangToCommands(String code);

    /**
     * Parse an execute block and return an ExecuteBlock object.
     * @param code The execute block code to parse
     * @return An ExecuteBlock object
     */
    public static native ExecuteBlock parseExecuteBlock(String code);
}
