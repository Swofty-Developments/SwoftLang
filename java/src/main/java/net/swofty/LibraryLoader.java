package net.swofty;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;

import net.swofty.nativebridge.NativeBridge;

public class LibraryLoader {
    static {
        final String libName = "SwoftLang"; // <System.loadLibrary>
        final String resourcePath = "/Debug/SwoftLang.dll";

        try {
            // 1) try the standard lookup first (works in IDE)
            System.loadLibrary(libName);
        } catch (UnsatisfiedLinkError initial) {
            // 2) fall back to extracting the DLL from inside the JAR
            try {
                Path extracted = extractTemp(resourcePath, libName, ".dll");
                System.load(extracted.toString());
            } catch (IOException | UnsatisfiedLinkError ex) {
                // We tried both mechanisms – re-throw the original for clarity
                throw initial;
            }
        }
    }

    private static Path extractTemp(String resPath,
            String stem,
            String suffix) throws IOException {

        // Create a unique temp file – e.g. SwoftLang-123456.dll
        Path temp = Files.createTempFile(stem + "-", suffix);
        temp.toFile().deleteOnExit();

        try (InputStream in = NativeBridge.class.getResourceAsStream(resPath)) {
            if (in == null) {
                throw new IOException("Native resource not found: " + resPath);
            }
            Files.copy(in, temp, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        }

        return temp;
    }
}
