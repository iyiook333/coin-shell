package com.xyxy.coinshell.service;

import com.xyxy.coinshell.entity.dto.ExchangeResponse;

public interface ExchangeService {
    ExchangeResponse exchange(Long userId, Integer amount);
}