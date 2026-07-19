package net.swofty.compiler;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;

/**
 * Locates and runs the swoftc OCaml compiler, returning the JSON AST it emits.
 * Resolution order: SWOFTC env var, `swoftc` on PATH, a repo-relative
 * compiler/_build/default/bin/main.exe found by walking up from the working
 * directory, then a native swoftc bundled inside this jar for the current
 * OS/arch (extracted to a temp file). With no binary available, a
 * `<script>.sw.json` sidecar is used. The bundled binary is what makes a
 * released jar self-contained: no separate compiler to install.
 */
public class SwoftcCompiler {
    private static final String BUILD_RELATIVE_PATH = "compiler/_build/default/bin/main.exe";

    /** Path to the extracted bundled binary, resolved once per JVM. */
    private static volatile String bundledBinary;
    private static volatile boolean bundledResolved;

    /**
     * Compile a script file to its JSON AST
     * @param scriptFile The .sw script file
     * @return The JSON AST as a string
     */
    public static String compile(File scriptFile) throws IOException, InterruptedException {
        return compile(scriptFile, null);
    }

    /**
     * Compile a script file to its JSON AST, resolving bare imports against
     * the given addon directory (design 6A). Relative imports always resolve
     * against the importing script's own directory.
     * @param scriptFile The .sw entry file
     * @param addonPath Directory searched for {@code import "name"}, or null
     * @return The JSON AST as a string (flat shape, or a module bundle when
     *         the script imports modules)
     */
    public static String compile(File scriptFile, File addonPath)
            throws IOException, InterruptedException {
        String binary = resolveBinary();
        if (binary == null) {
            File sidecar = new File(scriptFile.getPath() + ".json");
            if (sidecar.isFile()) {
                return Files.readString(sidecar.toPath());
            }
            throw new IOException("Cannot compile " + scriptFile.getPath()
                    + ": no swoftc binary found (checked SWOFTC env var, 'swoftc' on PATH, and "
                    + BUILD_RELATIVE_PATH + " walking up from " + new File("").getAbsolutePath()
                    + ") and no sidecar at " + sidecar.getPath());
        }

        List<String> command = new ArrayList<>(
                List.of(binary, "compile", scriptFile.getAbsolutePath()));
        if (addonPath != null) {
            command.add("--addon-path");
            command.add(addonPath.getAbsolutePath());
        }
        Process process = new ProcessBuilder(command).start();
        ByteArrayOutputStream stderrBuffer = new ByteArrayOutputStream();
        Thread stderrReader = new Thread(() -> {
            try (InputStream err = process.getErrorStream()) {
                err.transferTo(stderrBuffer);
            } catch (IOException ignored) {
            }
        });
        stderrReader.start();

        String stdout = new String(process.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        stderrReader.join();
        int exitCode = process.waitFor();

        String stderr = stderrBuffer.toString(StandardCharsets.UTF_8).trim();
        if (exitCode != 0) {
            throw new IOException("swoftc failed for " + scriptFile.getPath() + " (exit " + exitCode + "): "
                    + stderr);
        }
        if (!stderr.isEmpty()) {
            // swoftc emits warnings on stderr even when compilation succeeds
            for (String warningLine : stderr.split("\n")) {
                System.err.println("[swoftc] " + warningLine);
            }
        }
        return stdout;
    }

    private static String resolveBinary() {
        String env = System.getenv("SWOFTC");
        if (env != null && !env.isEmpty()) {
            File candidate = new File(env);
            if (candidate.isFile() && candidate.canExecute()) {
                return candidate.getAbsolutePath();
            }
        }

        String path = System.getenv("PATH");
        if (path != null) {
            for (String dir : path.split(File.pathSeparator)) {
                if (dir.isEmpty()) {
                    continue;
                }
                File candidate = new File(dir, "swoftc");
                if (candidate.isFile() && candidate.canExecute()) {
                    return candidate.getAbsolutePath();
                }
            }
        }

        for (File dir = new File("").getAbsoluteFile(); dir != null; dir = dir.getParentFile()) {
            File candidate = new File(dir, BUILD_RELATIVE_PATH);
            if (candidate.isFile() && candidate.canExecute()) {
                return candidate.getAbsolutePath();
            }
        }

        return extractBundledBinary();
    }

    /**
     * Extract the native swoftc bundled in this jar for the running OS/arch to a
     * temp file (once per JVM). Returns null if this jar carries no matching
     * binary — e.g. a development build, where the walk-up above finds the one
     * built by dune.
     */
    private static String extractBundledBinary() {
        if (bundledResolved) {
            return bundledBinary;
        }
        synchronized (SwoftcCompiler.class) {
            if (bundledResolved) {
                return bundledBinary;
            }
            bundledResolved = true;
            String resource = bundledResourceName();
            if (resource == null) {
                return null;
            }
            try (InputStream in = SwoftcCompiler.class.getResourceAsStream("/swoftc/" + resource)) {
                if (in == null) {
                    return null;
                }
                boolean windows = resource.endsWith(".exe");
                File tmp = Files.createTempFile("swoftc", windows ? ".exe" : "").toFile();
                tmp.deleteOnExit();
                Files.copy(in, tmp.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
                tmp.setExecutable(true);
                bundledBinary = tmp.getAbsolutePath();
            } catch (IOException e) {
                System.err.println("[swoftc] failed to extract bundled compiler: " + e.getMessage());
            }
            return bundledBinary;
        }
    }

    /**
     * Resource name of the bundled swoftc for the current platform, e.g.
     * {@code linux-x64}, {@code macos-arm64}, {@code windows-x64.exe}. Null for
     * an unrecognized platform.
     */
    private static String bundledResourceName() {
        String os = System.getProperty("os.name", "").toLowerCase();
        String arch = System.getProperty("os.arch", "").toLowerCase();
        String archTag = switch (arch) {
            case "aarch64", "arm64" -> "arm64";
            case "amd64", "x86_64", "x64" -> "x64";
            default -> null;
        };
        if (archTag == null) {
            return null;
        }
        if (os.contains("win")) {
            return "windows-" + archTag + ".exe";
        }
        if (os.contains("mac") || os.contains("darwin")) {
            return "macos-" + archTag;
        }
        if (os.contains("nux") || os.contains("nix")) {
            return "linux-" + archTag;
        }
        return null;
    }
}
