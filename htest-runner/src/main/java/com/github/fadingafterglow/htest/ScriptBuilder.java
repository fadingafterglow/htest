package com.github.fadingafterglow.htest;

import com.github.fadingafterglow.htest.data.TestCase;
import com.github.fadingafterglow.htest.data.TestContext;

import java.util.List;

public class ScriptBuilder {

    public String build(String moduleName, List<TestContext> tests) {
        StringBuilder script = new StringBuilder();

        addHeader(script, moduleName);
        addImports(script, tests);
        addTests(script, moduleName, tests);
        addTestProcessing(script);

        return script.toString();
    }

    private void addHeader(StringBuilder script, String moduleName) {
        script.append(":set prompt \"\"").append("\n");
        script.append(":load ").append(moduleName).append("\n");
    }

    private void addImports(StringBuilder script, List<TestContext> tests) {
        tests.stream()
                .flatMap(testContext -> testContext.imports().stream())
                .distinct()
                .forEach(i -> script.append("import ").append(i).append("\n"));
    }

    private void addTests(StringBuilder script, String moduleName, List<TestContext> tests) {
        script.append("let tests = [ ");
        for (TestContext testContext : tests) {
            for (TestCase testCase : testContext.testCases()) {
                script.append("let actual = (");
                script.append(moduleName);
                script.append('.');
                script.append(testContext.function());
                script.append(' ');
                script.append(testCase.arguments());
                script.append("); expected = (");
                script.append(testCase.expectedResult());
                script.append(") in (expected == actual, \"");
                script.append(testContext.function());
                script.append(' ');
                script.append(escape(testCase.arguments()));
                script.append("\\nExpected: \" ++ show expected ++ \"\\nActual: \" ++ show actual),");
            }
        }
        script.setCharAt(script.length() - 1, ']');
        script.append("\n");
    }

    private String escape(String str) {
        return str.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private void addTestProcessing(StringBuilder script) {
        script.append("""
        mapM_ (\\ t -> putStrLn (snd t ++ (if fst t then "\\nPASS\\n" else "\\nFAIL\\n"))) tests
        putStrLn ("Total: " ++ show (length tests))
        putStrLn ("Failed: " ++ show (length (filter (\\ t -> fst t == False) tests)))
        """);
    }
}
