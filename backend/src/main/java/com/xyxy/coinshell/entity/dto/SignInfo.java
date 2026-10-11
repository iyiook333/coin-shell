package com.xyxy.coinshell.entity.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SignInfo {
    private String month;        // 如 "2026-08"
    private Integer monthDays;   // 本月已签到天数
    private Boolean todaySigned; // 今日是否已签到
    private Integer coin;        // 今日签到获得金币数
}