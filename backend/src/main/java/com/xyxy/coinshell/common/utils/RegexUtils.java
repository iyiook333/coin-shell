package com.xyxy.coinshell.common.utils;

public class RegexUtils {
    public static boolean isPhoneValid(String phone) {
        return phone != null && phone.matches(RegexPatterns.PHONE_REGEX);
    }
}
