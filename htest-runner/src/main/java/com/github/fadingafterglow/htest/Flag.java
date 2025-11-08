package com.github.fadingafterglow.htest;

public enum Flag {
    SILENT;

    public static boolean isFlag(String str) {
        if(!str.trim().startsWith("--")) {
            return false;
        }
        str = str.substring(2);
        try {
            valueOf(str.toUpperCase());
            return true;
        } catch (Exception ex) {
            return false;
        }
    }

    public static Flag toFlag(String str) {
        str = str.substring(2);
        return valueOf(str.toUpperCase());
    }
}
