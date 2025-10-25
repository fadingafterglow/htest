package com.github.fadingafterglow.htest;

import com.github.fadingafterglow.htest.data.TestContext;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Stream;

public class Runner {

    private static final String KEEP_TEMP_FILES_ENV = "HTEST_KEEP_TEMP_FILES";

    public static void main(String[] args) throws IOException, InterruptedException {
        checkArgs(args);
        String moduleName = getModuleName(args);
        List<Path> testFiles = getTestFiles(args);

        List<TestContext> tests = new FileProcessor().process(testFiles);
        String script = new ScriptBuilder().build(moduleName, tests);
        File scriptFile = saveToTempFile(script);

        List<String> packages = extractPackages(tests);
        Process ghciProcess = invokeGhci(scriptFile, packages);
        ghciProcess.waitFor();
    }

    private static void checkArgs(String[] args) {
        if (args.length < 2) {
            System.err.println("At least two arguments required: module name and test file");
            System.exit(1);
        }
    }

    private static List<String> extractPackages(List<TestContext> tests) {
        return tests.stream()
                .flatMap(tc -> tc.packages().stream())
                .distinct()
                .flatMap(pkg -> Stream.of("-package", pkg))
                .toList();
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

    private static Process invokeGhci(File script, List<String> packageArgs) throws IOException {
        List<String> command = new ArrayList<>();
        command.add("ghci");
        command.addAll(packageArgs);

        return new ProcessBuilder(command)
                .redirectInput(script)
                .redirectOutput(ProcessBuilder.Redirect.INHERIT)
                .redirectError(ProcessBuilder.Redirect.INHERIT)
                .start();
    }
}
