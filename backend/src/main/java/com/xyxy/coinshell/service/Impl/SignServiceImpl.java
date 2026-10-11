package com.xyxy.coinshell.service.Impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.xyxy.coinshell.common.utils.BusinessException;
import com.xyxy.coinshell.entity.dto.SignInfo;
import com.xyxy.coinshell.entity.po.EarningsDetail;
import com.xyxy.coinshell.entity.po.SignRecord;
import com.xyxy.coinshell.entity.po.UserCoin;
import com.xyxy.coinshell.mapper.EarningsDetailMapper;
import com.xyxy.coinshell.mapper.SignRecordMapper;
import com.xyxy.coinshell.service.SignService;
import com.xyxy.coinshell.service.UserCoinService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.ThreadLocalRandom;

import static com.xyxy.coinshell.common.utils.RedisConstant.REDIS_KEY_PREFIX;
import static com.xyxy.coinshell.common.utils.constant.MAX_COIN;

@Service
@Slf4j
public class SignServiceImpl implements SignService {

    @Autowired
    private SignRecordMapper signRecordMapper;

    @Autowired
    private UserCoinService userCoinService;

    @Autowired
    private EarningsDetailMapper earningsDetailMapper;

    @Autowired
    private StringRedisTemplate redisTemplate;


    @Override
    @Transactional
    public SignInfo signIn(Long userId) {
        LocalDate today = LocalDate.now();

        // ========== 1. 先插入签到记录（利用唯一索引防重） ==========
        SignRecord record = new SignRecord();
        record.setUserId(userId);
        record.setSignDate(today);
        // coin_gained 先占位，后续更新
        record.setCoinGained(0);

        try {
            signRecordMapper.insert(record);
        } catch (DuplicateKeyException e) {
            throw new BusinessException("今日已签到");
        }

        // ========== 2. 随机金币（1-10） ==========
        int coin = ThreadLocalRandom.current().nextInt(1, MAX_COIN + 1);
        record.setCoinGained(coin);
        signRecordMapper.updateById(record);

        // ========== 3. 更新用户金币余额 ==========
        UserCoin uc = userCoinService.getOrCreate(userId);
        int oldCoin = uc.getCoinBalance();
        int newCoin = oldCoin + coin;
        uc.setCoinBalance(newCoin);
        uc.setTotalEarnedCoin(uc.getTotalEarnedCoin() + coin);
        userCoinService.updateById(uc);

        // ========== 4. 插入收益流水 ==========
        EarningsDetail detail = new EarningsDetail();
        detail.setUserId(userId);
        detail.setAssetType("coin");
        detail.setChangeType("sign");
        detail.setAmount(BigDecimal.valueOf(coin));
        detail.setBalanceAfter(BigDecimal.valueOf(newCoin));
        detail.setSourceId(record.getId());
        detail.setSourceType("sign");
        detail.setDescription("签到获得金币");
        earningsDetailMapper.insert(detail);

        // ========== 5. 统计本月签到天数 ==========
        LocalDate firstDay = today.withDayOfMonth(1);
        LambdaQueryWrapper<SignRecord> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SignRecord::getUserId, userId)
                .between(SignRecord::getSignDate, firstDay, today);
        Long monthDays = signRecordMapper.selectCount(wrapper);

        // ========== 6. 事务提交后，异步写 Redis Bitmap（由调用方通过事件触发） ==========
        // 注意：这里不直接写 Redis，而是返回结果，由 Controller 层发布事件
        // 这样保证 Redis 写失败不影响事务提交

        SignInfo info = new SignInfo();
        info.setMonth(today.format(DateTimeFormatter.ofPattern("yyyy-MM")));
        info.setMonthDays(monthDays.intValue());
        info.setTodaySigned(true);
        info.setCoin(coin);
        return info;
    }

    @Override
    public SignInfo getSignInfo(Long userId) {
        LocalDate today = LocalDate.now();

        // ========== 1. 先查 Redis Bitmap（快速） ==========
        int year = today.getYear();
        int dayOfYear = today.getDayOfYear() - 1;
        String key = REDIS_KEY_PREFIX + userId + ":" + year;
        Boolean cached = redisTemplate.opsForValue().getBit(key, dayOfYear);

        boolean todaySigned;
        if (Boolean.TRUE.equals(cached)) {
            // Redis 里显示已签到，直接返回
            todaySigned = true;
        } else {
            // 2. Redis 查不到（或为 false），降级查 MySQL
            LambdaQueryWrapper<SignRecord> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(SignRecord::getUserId, userId)
                    .eq(SignRecord::getSignDate, today);
            Long count = signRecordMapper.selectCount(wrapper);
            todaySigned = count > 0;
            // 3. 如果 MySQL 查到已签到，异步补 Redis（由调用方通过事件触发）
        }

        // 4. 统计本月签到天数（从 MySQL 查，更准确）
        LocalDate firstDay = today.withDayOfMonth(1);
        LambdaQueryWrapper<SignRecord> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SignRecord::getUserId, userId)
                .between(SignRecord::getSignDate, firstDay, today);
        Long monthDays = signRecordMapper.selectCount(wrapper);

        SignInfo info = new SignInfo();
        info.setMonth(today.format(DateTimeFormatter.ofPattern("yyyy-MM")));
        info.setMonthDays(monthDays.intValue());
        info.setTodaySigned(todaySigned);
        info.setCoin(0);
        return info;
    }
}