package com.xyxy.coinshell.config;

import com.xyxy.coinshell.common.utils.LoginInterceptor;
import com.xyxy.coinshell.common.utils.RefreshTokenInterceptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class MvcConfig implements WebMvcConfigurer {

    @Autowired
    private StringRedisTemplate stringRedisTemplate;
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LoginInterceptor())
                .addPathPatterns(
                        "/user/me" ,   // 个人信息
                        "/account/**",   // 所有记账相关
                        "/report/**",    // 所有报表相关
                        "/coin/**",       // 所有金币相关
                        "/sign/**"       // 所有签到相关

                ).order(2);
        registry.addInterceptor(new RefreshTokenInterceptor(stringRedisTemplate)).order(1);
    }
}
