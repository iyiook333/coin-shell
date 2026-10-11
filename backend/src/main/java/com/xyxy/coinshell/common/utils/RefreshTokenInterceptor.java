package com.xyxy.coinshell.common.utils;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.util.StrUtil;
import com.xyxy.coinshell.entity.vo.LoginVo;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

import java.util.Map;
import java.util.concurrent.TimeUnit;

public class RefreshTokenInterceptor implements HandlerInterceptor {

    private StringRedisTemplate stringRedisTemplate;

    public RefreshTokenInterceptor(StringRedisTemplate stringRedisTemplate) {
        this.stringRedisTemplate = stringRedisTemplate;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        //1.获取请求头中的 token
        String token = request.getHeader("Authorization");


        System.out.println("=== RefreshTokenInterceptor 执行，路径：" + request.getRequestURI());
        System.out.println("=== Token：" + token);


        //1.1.判断token是否存在
        if (StrUtil.isBlank(token)){
            return true;
        }
        //1.2.去掉 "Bearer " 前缀，还原为纯 Token
        if (token.startsWith("Bearer ")) {
            token = token.substring(7);
        }
        //2.获取redis中的用户
        Map<Object, Object> userMap = stringRedisTemplate.opsForHash().entries(RedisConstant.LOGIN_TOKEN_KEY + token);
        //3.判断用户是否存在
        if (userMap.isEmpty()) {
            return true;
        }
        //5.将查询到的Hash值转为LoginVo对象
        LoginVo loginVo = BeanUtil.fillBeanWithMap(userMap, new LoginVo(), false);
        //6.存在,保存到ThreadLocal
        LoginVoHolder.saveLoginVo(loginVo);
        //7.刷新token
        stringRedisTemplate.expire(RedisConstant.LOGIN_TOKEN_KEY + token, RedisConstant.LOGIN_TOKEN_TTL, TimeUnit.MINUTES);
        //8.放行
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler, Exception ex) throws Exception {
        LoginVoHolder.remove();
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, ModelAndView modelAndView) throws Exception {
        HandlerInterceptor.super.postHandle(request, response, handler, modelAndView);
    }
}
