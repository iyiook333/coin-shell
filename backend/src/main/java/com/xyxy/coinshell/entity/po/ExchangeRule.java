package com.xyxy.coinshell.entity.po;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("exchange_rule")
public class ExchangeRule {
    @TableId(type = IdType.AUTO)
    private Integer id;
    private Integer coinRate;
    private BigDecimal cashRate;
    private BigDecimal minCash;
    private BigDecimal maxCash;
    private BigDecimal dailyLimit;
    private Boolean isActive;
    private LocalDateTime updateTime;
}