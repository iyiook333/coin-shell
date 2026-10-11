package com.xyxy.coinshell.service.Impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.entity.dto.AccountDto;
import com.xyxy.coinshell.entity.po.AccountPo;
import com.xyxy.coinshell.entity.vo.AccountVo;
import com.xyxy.coinshell.entity.vo.CategoryStatisticsVo;
import com.xyxy.coinshell.entity.vo.StatisticsOverviewVo;
import com.xyxy.coinshell.entity.vo.TrendStatisticsVo;
import com.xyxy.coinshell.mapper.AccountMapper;
import com.xyxy.coinshell.service.AccountService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
public class AccountServiceImpl extends ServiceImpl<AccountMapper, AccountPo> implements AccountService {
    // todo 添加账户
    @Override
    public void addAccount(Long userId, AccountDto dto) {
        AccountPo accountPo = new AccountPo();
        accountPo.setUserId(userId);
        accountPo.setAmount(dto.getAmount());
        accountPo.setType(dto.getType());
        accountPo.setCategory(dto.getCategory());
        accountPo.setNote(dto.getNote());
        boolean save = save(accountPo);
        if (!save) {
            throw new RuntimeException("添加账户失败");
        }
        log.info("=== 插入结果: {}", save);
        log.info("=== 插入后 ID: {}", accountPo.getId());
    }
    @Override
    //todo 分页查询账户
    public Result<Map<String, Object>> pageByUser(Long userId, Integer page, Integer size) {
        // 1. 构建查询条件：按用户ID过滤，按记账时间倒序
        LambdaQueryWrapper<AccountPo> wrapper = new LambdaQueryWrapper<>();
        // 1.2. 添加查询条件：user_id = ? 并且按 account_time 倒序排列
        wrapper.eq(AccountPo::getUserId, userId)
                .orderByDesc(AccountPo::getAccountTime);
        // 2. 分页查询
        Page<AccountPo> pageResult = page(new Page<>(page, size), wrapper);
        // 3. PO → VO 转换
        List<AccountVo> records = pageResult.getRecords().stream().map(po -> {
            AccountVo vo = new AccountVo();
            BeanUtils.copyProperties(po, vo);
            return vo;
        }).collect(Collectors.toList());

        // 4. 组装返回数据
        Map<String, Object> data = new HashMap<>();
        data.put("records", records);
        data.put("total", pageResult.getTotal());
        data.put("size", pageResult.getSize());
        data.put("current", pageResult.getCurrent());
        data.put("pages", pageResult.getPages());

        return Result.success(data);
    }
    // todo 获取统计 overview
    @Override
    public Result<StatisticsOverviewVo> getStatisticsOverview(Long userId, String month) {
        // 1. 解析月份，得到开始日期和结束日期
        YearMonth yearMonth = YearMonth.parse(month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();
        // 2. 构造查询条件：userId + 日期范围
        LambdaQueryWrapper<AccountPo> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(AccountPo::getUserId, userId)
                .between(AccountPo::getAccountTime, startDate.atStartOfDay(), endDate.atTime(23, 59, 59));
        // 3. 查询账单列表
        List<AccountPo> list = list(wrapper);
        // 4. 遍历累加收入和支出
        BigDecimal totalIncome = BigDecimal.ZERO;
        BigDecimal totalExpense = BigDecimal.ZERO;
        for (AccountPo po : list) {
            if (Integer.valueOf(1).equals(po.getType())) {
                totalIncome = totalIncome.add(po.getAmount());
            } else {
                totalExpense = totalExpense.add(po.getAmount());
            }
        }
        // 5. 计算结余
        BigDecimal balance = totalIncome.subtract(totalExpense);
        // 6. 返回结果
        return Result.success(new StatisticsOverviewVo(totalIncome, totalExpense, balance));
    }

    // todo 获取统计 category
    @Override
    public Result<List<CategoryStatisticsVo>> getCategoryStatistics(Long userId, String month) {
        // 1. 解析月份，得到开始日期和结束日期
        YearMonth yearMonth = YearMonth.parse(month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();
        // 2. 构造查询条件：userId + 支出类型 + 日期范围
        LambdaQueryWrapper<AccountPo> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(AccountPo::getUserId, userId)
                .eq(AccountPo::getType, 2)
                .between(AccountPo::getAccountTime, startDate.atStartOfDay(), endDate.atTime(23, 59, 59));
        // 3. 查询账单列表
        List<AccountPo> list = list(wrapper);
        // 4. 用 Map 按分类分组汇总
        Map<String, BigDecimal> categorySum = new HashMap<>();
        // 5. 计算总金额
        BigDecimal total = BigDecimal.ZERO;
        for (AccountPo po : list) {
            String category = po.getCategory();
            BigDecimal amount = po.getAmount();
            categorySum.merge(category, amount, BigDecimal::add);
            total = total.add(amount);
        }
        // 6. 遍历 Map，计算每个分类的占比
        final BigDecimal finalTotal = total;
        List<CategoryStatisticsVo> result = categorySum.entrySet().stream()
                .map(entry -> {
                    String category = entry.getKey();
                    BigDecimal amount = entry.getValue();
                    double percent = 0;
                    if (finalTotal.compareTo(BigDecimal.ZERO) > 0) {
                        percent = amount.multiply(BigDecimal.valueOf(100))
                                .divide(finalTotal, 1, RoundingMode.HALF_UP)
                                .doubleValue();
                    }
                    return new CategoryStatisticsVo(category, amount, percent);
                })
        // 7. 按金额从大到小排序
                .sorted((o1, o2) -> o2.getAmount().compareTo(o1.getAmount()))
                .collect(Collectors.toList());
        // 8. 返回结果
        return Result.success(result);
    }

    // todo 获取统计 trend
    @Override
    public Result<List<TrendStatisticsVo>> getStatisticsTrend(Long userId) {
        // 初始化结果列表
        List<TrendStatisticsVo> result = new ArrayList<>();
        // 1. 获取今天日期
        LocalDate today = LocalDate.now();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM-dd");
        // 2. 循环7次（i = 6 到 0）
        for (int i = 6; i >= 0; i--){
            // 3. 取当天日期，格式化成 MM-dd
            LocalDate date = today.minusDays(i);
            String formattedDate = date.format(formatter);
            LocalDate startDate = date;
            LocalDate endDate = date;
            // 4. 构造查询条件：userId + 当天日期范围
            LambdaQueryWrapper<AccountPo> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(AccountPo::getUserId, userId)
                    .between(AccountPo::getAccountTime, startDate.atStartOfDay(), endDate.atTime(23, 59, 59));
            // 5. 查询账单列表
            List<AccountPo> list = list(wrapper);
            BigDecimal income = BigDecimal.ZERO;
            BigDecimal expense = BigDecimal.ZERO;
            // 6. 遍历累加收入和支出
            for (AccountPo po : list) {
                if (po.getType().equals(1)) {
                    income = income.add(po.getAmount());
                } else {
                    expense = expense.add(po.getAmount());
                }
            }
            // 7. 添加到结果列表
            result.add(new TrendStatisticsVo(formattedDate, income, expense));
        }

        // 8. 返回结果
        return Result.success(result);
    }

    // todo 删除账单
    @Override
    public void deleteAccount(Long userId, Long id) {
        // 1. 查询账单是否存在
        AccountPo accountPo = getById(id);
        if (accountPo == null) {
            throw new RuntimeException("账单不存在");
        }
        // 2. 校验是否是当前用户的账单（防止越权删除）
        if (!accountPo.getUserId().equals(userId)) {
            throw new RuntimeException("无权限删除");
        }
        // 3. 执行删除
        boolean result = removeById(id);
        if (!result) {
            throw new RuntimeException("删除失败");
        }
        log.info("=== 删除结果: {}", result);
    }

}
