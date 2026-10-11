package com.xyxy.coinshell.entity.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryStatisticsVo {
    private String category;
    private BigDecimal amount;
    private Double percent;
}