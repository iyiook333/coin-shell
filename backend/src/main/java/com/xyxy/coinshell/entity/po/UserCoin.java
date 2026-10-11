package com.xyxy.coinshell.entity.po;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("user_coin")
public class UserCoin {
    @TableId
    private Long userId;
    private Integer coinBalance;
    private BigDecimal cashBalance;
    private Integer totalEarnedCoin;
    private BigDecimal totalWithdrawnCash;
    private LocalDateTime updatedAt;
}