package com.xyxy.coinshell.service;

import com.xyxy.coinshell.entity.dto.FlashInfo;

public interface FlashGrabService {
    FlashInfo getStatus(Long userId);
    FlashInfo grab(Long userId);
}