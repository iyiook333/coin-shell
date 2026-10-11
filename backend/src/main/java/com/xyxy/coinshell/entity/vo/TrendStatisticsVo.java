package com.xyxy.coinshell.entity.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TrendStatisticsVo {
    private String date;      // MM-dd
    private BigDecimal income;
    private BigDecimal expense;
}