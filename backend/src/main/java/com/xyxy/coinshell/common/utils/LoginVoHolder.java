package com.xyxy.coinshell.common.utils;

import com.xyxy.coinshell.entity.vo.LoginVo;

public class LoginVoHolder {
    private static final ThreadLocal<LoginVo> tl = new ThreadLocal<>();

    public static void saveLoginVo(LoginVo loginVo) {
        tl.set(loginVo);
    }

    public static LoginVo getLoginVo() {
        return tl.get();
    }

    public static void remove() {
        tl.remove();
    }
}
