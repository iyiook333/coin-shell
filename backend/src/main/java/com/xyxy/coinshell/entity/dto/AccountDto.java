package com.xyxy.coinshell.entity.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccountDto {
    private BigDecimal amount;
    private Integer type;
    private String category;
    private String note;
}
