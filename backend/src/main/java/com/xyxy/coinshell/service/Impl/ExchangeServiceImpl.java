package com.xyxy.coinshell.service.Impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.xyxy.coinshell.common.utils.BusinessException;
import com.xyxy.coinshell.entity.dto.ExchangeResponse;
import com.xyxy.coinshell.entity.po.EarningsDetail;
import com.xyxy.coinshell.entity.po.ExchangeRule;
import com.xyxy.coinshell.entity.po.UserCoin;
import com.xyxy.coinshell.mapper.EarningsDetailMapper;
import com.xyxy.coinshell.mapper.ExchangeRuleMapper;
import com.xyxy.coinshell.mapper.UserCoinMapper;
import com.xyxy.coinshell.service.ExchangeService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;

@Service
@Slf4j
public class ExchangeServiceImpl implements ExchangeService {

    @Autowired
    private UserCoinMapper userCoinMapper;

    @Autowired
    private ExchangeRuleMapper exchangeRuleMapper;

    @Autowired
    private EarningsDetailMapper earningsDetailMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ExchangeResponse exchange(Long userId, Integer amount) {
        // ========== 1. 参数校验 ==========
        if (amount == null || amount <= 0) {
            throw new BusinessException("兑换金额必须大于0");
        }

        // ========== 2. 获取兑换规则（从数据库读取，支持运营动态调整） ==========
        ExchangeRule rule = exchangeRuleMapper.getActiveRule();
        if (rule == null) {
            throw new BusinessException("系统暂不支持兑换，请联系客服");
        }

        // 校验单次兑换上限/下限
        BigDecimal amountDecimal = BigDecimal.valueOf(amount);
        if (amountDecimal.compareTo(rule.getMinCash()) < 0) {
            throw new BusinessException("单次最低兑换 " + rule.getMinCash() + " 元");
        }
        if (amountDecimal.compareTo(rule.getMaxCash()) > 0) {
            throw new BusinessException("单次最高兑换 " + rule.getMaxCash() + " 元");
        }

        // ========== 3. 计算需要多少金币 ==========
        int coinNeeded = amount * rule.getCoinRate();  // amount * 100

        // ========== 4. 查询用户余额 ==========
        UserCoin uc = userCoinMapper.selectById(userId);
        if (uc == null) {
            throw new BusinessException("用户不存在");
        }

        // 检查金币是否足够
        if (uc.getCoinBalance() < coinNeeded) {
            throw new BusinessException("金币不足，当前仅 " + uc.getCoinBalance() + " 金币，需要 " + coinNeeded + " 金币");
        }
        // 在兑换前检查每日限额
        if (rule.getDailyLimit() != null) {
            // 统计今日已兑换总额
            LocalDate today = LocalDate.now();
            LambdaQueryWrapper<EarningsDetail> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(EarningsDetail::getUserId, userId)
                    .eq(EarningsDetail::getAssetType, "cash")
                    .eq(EarningsDetail::getChangeType, "exchange_in")
                    .ge(EarningsDetail::getCreateTime, today.atStartOfDay())
                    .le(EarningsDetail::getCreateTime, today.atTime(23, 59, 59));
            BigDecimal todayCash = earningsDetailMapper.selectList(wrapper)
                    .stream()
                    .map(EarningsDetail::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            if (todayCash.add(amountDecimal).compareTo(rule.getDailyLimit()) > 0) {
                throw new BusinessException("今日兑换已达上限 " + rule.getDailyLimit() + " 元");
            }
        }

        // ========== 5. 执行兑换（双资产变更） ==========
        int oldCoin = uc.getCoinBalance();
        BigDecimal oldCash = uc.getCashBalance();

        // 扣金币
        int newCoin = oldCoin - coinNeeded;
        // 加现金
        BigDecimal newCash = oldCash.add(amountDecimal);

        uc.setCoinBalance(newCoin);
        uc.setCashBalance(newCash);
        userCoinMapper.updateById(uc);

        // ========== 6. 记录流水 ==========

        // 6.1 金币减少流水
        EarningsDetail coinDetail = new EarningsDetail();
        coinDetail.setUserId(userId);
        coinDetail.setAssetType("coin");
        coinDetail.setChangeType("exchange_out");
        coinDetail.setAmount(BigDecimal.valueOf(-coinNeeded));
        coinDetail.setBalanceAfter(BigDecimal.valueOf(newCoin));
        coinDetail.setDescription("兑换现金消耗金币");
        earningsDetailMapper.insert(coinDetail);

        // 6.2 现金增加流水
        EarningsDetail cashDetail = new EarningsDetail();
        cashDetail.setUserId(userId);
        cashDetail.setAssetType("cash");
        cashDetail.setChangeType("exchange_in");
        cashDetail.setAmount(amountDecimal);
        cashDetail.setBalanceAfter(newCash);
        cashDetail.setDescription("金币兑换现金");
        earningsDetailMapper.insert(cashDetail);

        log.info("兑换成功：用户 {}, 兑换 {} 元, 消耗 {} 金币, 剩余金币 {}, 剩余现金 {}",
                userId, amount, coinNeeded, newCoin, newCash);

        // ========== 7. 返回结果 ==========
        ExchangeResponse response = new ExchangeResponse();
        response.setNewCoin((double) newCoin);
        response.setNewCash(newCash.doubleValue());
        return response;
    }
}