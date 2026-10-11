package com.xyxy.coinshell.entity.dto;

import lombok.Data;

@Data
public class BillParseRequest {
    private String text;
    private String sessionId;
    private Long userId;
}