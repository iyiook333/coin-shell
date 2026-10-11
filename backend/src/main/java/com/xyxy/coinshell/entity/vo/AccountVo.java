package com.xyxy.coinshell.entity.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccountVo {
    private Long id;              // 账单 ID
    private BigDecimal amount;    // 金额
    private Integer type;         // 1-收入 2-支出
    private String category;      // 分类
    private String note;          // 备注
    private LocalDateTime accountTime;  // 记账时间（前端展示日期）
}