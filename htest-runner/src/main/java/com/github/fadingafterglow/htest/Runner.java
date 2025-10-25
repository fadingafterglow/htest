package com.github.fadingafterglow.htest;

import com.github.fadingafterglow.htest.data.TestContext;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;

public class Runner {

    private static final String KEEP_TEMP_FILES_ENV = "HTEST_KEEP_TEMP_FILES";

    public static void main(String[] args) throws IOException, InterruptedException {
        checkArgs(args);
        String moduleName = getModuleName(args);
        List<Path> testFiles = getTestFiles(args);

        List<TestContext> tests = new FileProcessor().process(testFiles);
        String script = new ScriptBuilder().build(moduleName, tests);
        List<String> ghciCommand = new GhciCommandBuilder().build(tests);
        File scriptFile = saveToTempFile(script);

        Process ghciProcess = invokeGhci(ghciCommand, scriptFile);
        ghciProcess.waitFor();
    }

    private static void checkArgs(String[] args) {
        if (args.length < 2) {
            System.err.println("At least two arguments required: module name and test file");
            System.exit(1);
        }
    }

    private static String getModuleName(String[] args) {
        return args[0];
    }

    private static List<Path> getTestFiles(String[] args) {
        return Arrays.stream(args)
                .skip(1)
                .map(Path::of)
                .toList();
    }

    private static File saveToTempFile(String script) throws IOException {
        Path path = Files.createTempFile("htest_", ".ghci");
        Files.writeString(path, script);
        File file = path.toFile();
        if (System.getenv(KEEP_TEMP_FILES_ENV) == null)
            file.deleteOnExit();
        return file;
    }

    private static Process invokeGhci(List<String> command, File script) throws IOException {
        return new ProcessBuilder(command)
                .redirectInput(script)
                .redirectOutput(ProcessBuilder.Redirect.INHERIT)
                .redirectError(ProcessBuilder.Redirect.INHERIT)
                .start();
    }
}
