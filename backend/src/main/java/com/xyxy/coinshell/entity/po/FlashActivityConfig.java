package com.xyxy.coinshell.entity.po;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalTime;
import java.time.LocalDateTime;

@Data
@TableName("flash_activity_config")
public class FlashActivityConfig {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String activityName;
    private LocalTime startTime;
    private LocalTime endTime;
    private Integer totalQuota;
    private Integer coinAmount;
    private Integer perUserLimit;
    private Boolean isActive;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}