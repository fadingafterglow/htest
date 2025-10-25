package com.github.fadingafterglow.htest;

import com.github.fadingafterglow.htest.data.TestContext;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Stream;

public class GhciCommandBuilder {

    private static final String GHCI_PATH_ENV = "HTEST_GHCI_PATH";

    public List<String> build(List<TestContext> tests) {
        List<String> ghciCommand = new ArrayList<>();
        ghciCommand.add(getGhciPath());
        ghciCommand.addAll(buildPackageArguments(tests));
        return ghciCommand;
    }

    private static String getGhciPath() {
        String ghciPath = System.getenv(GHCI_PATH_ENV);
        if (ghciPath == null || ghciPath.isBlank())
            ghciPath = "ghci";
        return ghciPath;
    }

    private static List<String> buildPackageArguments(List<TestContext> tests) {
        return tests.stream()
                .flatMap(tc -> tc.packages().stream())
                .distinct()
                .flatMap(pkg -> Stream.of("-package", pkg))
                .toList();
    }
}
