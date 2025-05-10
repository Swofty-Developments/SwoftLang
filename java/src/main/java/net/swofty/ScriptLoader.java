package net.swofty;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Generic script loader that handles file operations without assuming content type
 */
public class ScriptLoader {
    private final String scriptsDirectory;
    private final String fileExtension;
    private final List<File> scriptFiles = new ArrayList<>();
    
    public ScriptLoader(String scriptsDirectory, String fileExtension) {
        this.scriptsDirectory = scriptsDirectory;
        this.fileExtension = fileExtension;
    }
    
    /**
     * Scans the scripts directory for files matching the specified extension
     * @return List of script files found
     */
    public List<File> scanScripts() {
        scriptFiles.clear();
        
        // Ensure the scripts directory exists
        File directory = new File(scriptsDirectory);
        if (!directory.exists()) {
            directory.mkdirs();
            System.out.println("Created scripts directory at: " + directory.getAbsolutePath());
            return scriptFiles;
        }
        
        try {
            // Find all script files in the directory
            try (Stream<Path> paths = Files.walk(Paths.get(scriptsDirectory))) {
                scriptFiles.addAll(
                    paths.filter(Files::isRegularFile)
                         .filter(path -> path.toString().endsWith("." + fileExtension))
                         .map(Path::toFile)
                         .collect(Collectors.toList())
                );
            }
        } catch (IOException e) {
            System.err.println("Error scanning scripts directory: " + e.getMessage());
            e.printStackTrace();
        }
        
        return scriptFiles;
    }
    
    /**
     * Reads a script file's content
     * @param file The script file to read
     * @return The content of the script file as a string
     * @throws IOException If the file cannot be read
     */
    public String readScriptContent(File file) throws IOException {
        return Files.readString(file.toPath());
    }
    
    /**
     * Returns all currently found script files
     * @return List of script files
     */
    public List<File> getScriptFiles() {
        return scriptFiles;
    }
}