package com.github.fadingafterglow.htest.data;

import java.util.List;

public record TestContext(String function, List<TestCase> testCases, List<String> imports) {}
