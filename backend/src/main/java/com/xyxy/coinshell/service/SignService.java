package com.xyxy.coinshell.service;

import com.xyxy.coinshell.entity.dto.SignInfo;

public interface SignService {
    SignInfo signIn(Long userId);
    SignInfo getSignInfo(Long userId);
}