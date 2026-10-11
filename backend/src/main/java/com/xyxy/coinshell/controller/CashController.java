package com.xyxy.coinshell.controller;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.LoginVoHolder;
import com.xyxy.coinshell.entity.dto.ExchangeRequest;
import com.xyxy.coinshell.entity.dto.ExchangeResponse;
import com.xyxy.coinshell.service.ExchangeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/cash")
public class CashController {

    @Autowired
    private ExchangeService exchangeService;

    /**
     * 金币兑换现金
     * POST /cash/exchange
     * 请求体: { "amount": 1 }
     * 响应: { "newCoin": 950, "newCash": 1.00 }
     */
    @PostMapping("/exchange")
    public Result<ExchangeResponse> exchange(@RequestBody ExchangeRequest request) {
        Long userId = LoginVoHolder.getLoginVo().getId();
        ExchangeResponse response = exchangeService.exchange(userId, request.getAmount());
        return Result.success(response);
    }
}