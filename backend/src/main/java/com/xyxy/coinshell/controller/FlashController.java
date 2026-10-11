package com.xyxy.coinshell.controller;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.LoginVoHolder;
import com.xyxy.coinshell.entity.dto.FlashInfo;
import com.xyxy.coinshell.service.FlashGrabService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/flash")
public class FlashController {

    @Autowired
    private FlashGrabService flashGrabService;

    /**
     * 获取限时领状态
     * GET /flash/status
     */
    @GetMapping("/status")
    public Result<FlashInfo> getStatus() {
        Long userId = LoginVoHolder.getLoginVo().getId();
        FlashInfo info = flashGrabService.getStatus(userId);
        return Result.success(info);
    }

    /**
     * 执行领取
     * POST /flash/grab
     */
    @PostMapping("/grab")
    public Result<FlashInfo> grab() {
        Long userId = LoginVoHolder.getLoginVo().getId();
        FlashInfo info = flashGrabService.grab(userId);
        return Result.success(info);
    }
}