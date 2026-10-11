// EarningsDetailVO.java
package com.xyxy.coinshell.entity.vo;

import lombok.Data;

@Data
public class EarningsDetailVO {
    private Long id;
    private String type;       // "income" 或 "expense"
    private String category;   // 中文描述，如 "签到"、"兑换收入"
    private Double amount;
    private String desc;
    private String createTime;
}