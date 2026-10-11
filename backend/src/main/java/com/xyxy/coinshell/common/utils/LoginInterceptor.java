package com.xyxy.coinshell.common.utils;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.HandlerInterceptor;

public class LoginInterceptor implements HandlerInterceptor {
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        System.out.println("=== LoginInterceptor 执行，路径：" + request.getRequestURI());
       //1.判断是否需要拦截(ThreadLocal中是否有用户)
        if (LoginVoHolder.getLoginVo() == null){
            System.out.println("=== 用户未登录，拦截！");
            response.setStatus(401);
            return false;
        }
        System.out.println("=== 用户已登录，放行");
        return true;
    }

}
