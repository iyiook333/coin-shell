package com.xyxy.coinshell.common.utils;

public class RedisConstant {
    public static final String LOGIN_CODE_KEY = "login:code:";
    public static final long LOGIN_CODE_TTL = 2;
    public static final long LOGIN_TOKEN_TTL = 30;
    public static final String LOGIN_TOKEN_KEY = "login:token:";
    public static final String REDIS_KEY_PREFIX = "user:sign:";
}
