package com.xyxy.coinshell.controller;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.LoginVoHolder;
import com.xyxy.coinshell.entity.dto.SignInfo;
import com.xyxy.coinshell.event.SignEvent;
import com.xyxy.coinshell.service.SignService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/sign")
public class SignController {

    @Autowired
    private SignService signService;

    @Autowired
    private ApplicationEventPublisher eventPublisher;

    /**
     * 查询签到信息
     * GET /sign/info
     */
    @GetMapping("/info")
    public Result<SignInfo> getSignInfo() {
        Long userId = LoginVoHolder.getLoginVo().getId();
        SignInfo info = signService.getSignInfo(userId);
        return Result.success(info);
    }

    /**
     * 执行签到
     * POST /sign/in
     */
    @PostMapping("/in")
    public Result<SignInfo> signIn() {
        Long userId = LoginVoHolder.getLoginVo().getId();
        SignInfo info = signService.signIn(userId);

        // 事务提交后，发布事件异步写 Redis Bitmap
        eventPublisher.publishEvent(new SignEvent(this, userId, LocalDate.now()));

        return Result.success(info);
    }
}