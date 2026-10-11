package com.xyxy.coinshell.entity.dto;

import lombok.Data;

@Data
public class HistoryMessage {
    private String role;   // "user" 或 "assistant"
    private String content;

}