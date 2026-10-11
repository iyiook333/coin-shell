package com.xyxy.coinshell.entity.po;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("earnings_detail")
public class EarningsDetail {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private String assetType;
    private String changeType;
    private BigDecimal amount;
    private BigDecimal balanceAfter;
    private Long sourceId;
    private String sourceType;
    private String description;
    private LocalDateTime createTime;
}