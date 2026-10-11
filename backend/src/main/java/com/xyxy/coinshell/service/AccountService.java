package com.xyxy.coinshell.service;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.entity.dto.AccountDto;
import com.xyxy.coinshell.entity.vo.CategoryStatisticsVo;
import com.xyxy.coinshell.entity.vo.StatisticsOverviewVo;
import com.xyxy.coinshell.entity.vo.TrendStatisticsVo;

import java.util.List;
import java.util.Map;

public interface AccountService {

    void addAccount(Long userId, AccountDto dto);

    Result<Map<String, Object>> pageByUser(Long userId, Integer page, Integer size);

    Result<StatisticsOverviewVo> getStatisticsOverview(Long userId, String month);

    Result<List<CategoryStatisticsVo>> getCategoryStatistics(Long userId, String month);

    Result<List<TrendStatisticsVo>> getStatisticsTrend(Long userId);

    void deleteAccount(Long userId, Long id);
}
