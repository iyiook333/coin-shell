package com.xyxy.coinshell.entity.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExchangeResponse {
    private Double newCoin;   // 兑换后金币余额
    private Double newCash;   // 兑换后现金余额
}