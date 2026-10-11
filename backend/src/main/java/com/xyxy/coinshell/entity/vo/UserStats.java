package com.xyxy.coinshell.entity.vo;


import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UserStats {
    //累计收益
    private Double totalEarnings;
    //完成任务
    private Integer completedTasks;
    //连续签到
    private Integer consecutiveSignIns;


}
