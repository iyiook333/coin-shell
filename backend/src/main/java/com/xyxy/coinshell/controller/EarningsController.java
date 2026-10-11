// EarningsController.java
package com.xyxy.coinshell.controller;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.LoginVoHolder;
import com.xyxy.coinshell.entity.vo.EarningsDetailVO;
import com.xyxy.coinshell.service.EarningsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/earnings")
public class EarningsController {

    @Autowired
    private EarningsService earningsService;

    @GetMapping("/list")
    public Result<List<EarningsDetailVO>> list(
            @RequestParam String type,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {
        Long userId = LoginVoHolder.getLoginVo().getId();
        List<EarningsDetailVO> list = earningsService.list(userId, type, page, size);
        return Result.success(list);
    }
}