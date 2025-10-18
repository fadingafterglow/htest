package com.github.fadingafterglow.htest;

import com.github.fadingafterglow.htest.data.TestCase;
import com.github.fadingafterglow.htest.data.TestContext;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;
import java.util.stream.Stream;

public class FileProcessor {

    private static final String COMMENT_PREFIX = "#/";
    private static final String IMPORT_PREFIX = "#import ";

    public List<TestContext> process(List<Path> paths) {
        List<TestContext> tests = paths.parallelStream()
                .map(this::process)
                .filter(Objects::nonNull)
                .toList();
        System.out.println("Successfully processed " + tests.size() + " test files.");
        return tests;
    }

    public TestContext process(Path path) {
        try (Stream<String> lines = Files.lines(path)) {
            Iterator<String> linesIterator = lines.iterator();

            List<TestCase> testCases = new ArrayList<>();
            List<String> imports = new ArrayList<>();

            while (linesIterator.hasNext()) {
                String line = linesIterator.next();
                if (shouldSkip(line)) continue;
                if (isImport(line))
                    imports.add(line.substring(IMPORT_PREFIX.length()));
                else {
                    String nextLine = linesIterator.next();
                    while (shouldSkip(nextLine))
                        nextLine = linesIterator.next();
                    testCases.add(new TestCase(line, nextLine));
                }
            }

            return new TestContext(getFunctionName(path), testCases, imports);
        }
        catch (IOException e) {
            System.err.println("Cannot read file: " + path);
        }
        catch (NoSuchElementException e) {
            System.err.println("Malformed test cases in file: " + path);
        }
        return null;
    }

    private boolean shouldSkip(String line) {
        return line.isEmpty() || line.startsWith(COMMENT_PREFIX);
    }

    private boolean isImport(String line) {
        return line.startsWith(IMPORT_PREFIX);
    }

    private String getFunctionName(Path filePath) {
        String filename = filePath.getFileName().toString();
        int dotIndex = filename.lastIndexOf('.');
        return (dotIndex == -1) ? filename : filename.substring(0, dotIndex);
    }
}
