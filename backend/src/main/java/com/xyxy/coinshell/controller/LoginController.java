package com.xyxy.coinshell.controller;

import cn.hutool.core.util.StrUtil;
import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.LoginVoHolder;
import com.xyxy.coinshell.entity.dto.LoginDto;
import com.xyxy.coinshell.entity.vo.LoginVo;
import com.xyxy.coinshell.entity.vo.UserStats;
import com.xyxy.coinshell.service.LoginService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/user")
public class LoginController {
    @Autowired
    private LoginService loginService;
// =================== 以下为用户登录、发送短信验证码、获取当前登录用户、退出登录接口 ===================
    /**
     * 登录
     */
    @PostMapping("/login")
    public Result<String> Login(@RequestBody LoginDto dto) {
        //验证手机号和验证码
        return loginService.login(dto);
    }

    /**
     * 发送短信验证码
     */
    @PostMapping("/code")
    public Result<String> sendCode(@RequestBody LoginDto dto) {
        //发送短信验证码并保存到redis
        return loginService.sendCode(dto.getPhone());
    }
    /**
     * 获取当前登录用户
     */
    @GetMapping("/me")
    public Result me(){
        //获取当前登录用户
        LoginVo loginVo = LoginVoHolder.getLoginVo();
        return Result.success(loginVo);
    }
    /**
     * 退出登录
     */
    @PostMapping("/logout")
    public Result<String> logout(HttpServletRequest request) {
        // 1.从请求头获取 Token
        String authorization = request.getHeader("Authorization");
        String token = null;
        if (StrUtil.isNotBlank(authorization) && authorization.startsWith("Bearer ")) {
            token = authorization.substring(7); // 剥离前缀
        }
        // 2.调用 Service 处理退出逻辑
        return loginService.logout(token);
    }

    /**
     * 获取用户统计信息
     */
    @GetMapping("/stats")
    public Result<UserStats> getUserStats() {
        Long userId = LoginVoHolder.getLoginVo().getId();
        return loginService.getUserStats(userId);
    }
}
