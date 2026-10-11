package com.xyxy.coinshell.entity.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FlashInfo {
    private Boolean grabbed;     // 今日是否已抢到
    private Integer remaining;   // 剩余名额
    private Boolean isActive;    // 是否在活动时间段内
    private String startTime;    // 活动开始时间 "10:00"
    private String endTime;      // 活动结束时间 "23:59"
}