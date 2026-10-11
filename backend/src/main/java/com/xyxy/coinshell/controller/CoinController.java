package com.xyxy.coinshell.controller;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.LoginVoHolder;
import com.xyxy.coinshell.entity.po.UserCoin;
import com.xyxy.coinshell.service.UserCoinService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

@RestController
@RequestMapping("/coin")
public class CoinController {

    @Autowired
    private UserCoinService userCoinService;

    @GetMapping("/balance")
    public Result<Integer> getBalance() {
        Long userId = LoginVoHolder.getLoginVo().getId();
        return Result.success(userCoinService.getOrCreate(userId).getCoinBalance());
    }

    @GetMapping("/cash")
    public Result<BigDecimal> getCashBalance() {
        Long userId = LoginVoHolder.getLoginVo().getId();
        UserCoin uc = userCoinService.getOrCreate(userId);
        return Result.success(uc.getCashBalance());
    }
}