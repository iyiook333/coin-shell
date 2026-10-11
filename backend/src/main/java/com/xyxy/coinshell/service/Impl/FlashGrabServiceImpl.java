package com.xyxy.coinshell.service.Impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.xyxy.coinshell.common.utils.BusinessException;
import com.xyxy.coinshell.entity.dto.FlashInfo;
import com.xyxy.coinshell.entity.po.EarningsDetail;
import com.xyxy.coinshell.entity.po.FlashActivityConfig;
import com.xyxy.coinshell.entity.po.FlashGrabRecord;
import com.xyxy.coinshell.entity.po.UserCoin;
import com.xyxy.coinshell.mapper.EarningsDetailMapper;
import com.xyxy.coinshell.mapper.FlashActivityConfigMapper;
import com.xyxy.coinshell.mapper.FlashGrabRecordMapper;
import com.xyxy.coinshell.mapper.UserCoinMapper;
import com.xyxy.coinshell.service.FlashGrabService;
import lombok.extern.slf4j.Slf4j;
import org.redisson.api.RLock;
import org.redisson.api.RedissonClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
public class FlashGrabServiceImpl implements FlashGrabService {

    @Autowired
    private FlashActivityConfigMapper configMapper;

    @Autowired
    private FlashGrabRecordMapper grabRecordMapper;

    @Autowired
    private UserCoinMapper userCoinMapper;

    @Autowired
    private EarningsDetailMapper earningsDetailMapper;

    @Autowired
    private StringRedisTemplate redisTemplate;

    @Autowired
    private RedissonClient redissonClient;

    private static final String QUOTA_KEY_PREFIX = "flash:quota:";

    @Override
    public FlashInfo getStatus(Long userId) {
        LocalDate today = LocalDate.now();
        FlashActivityConfig config = configMapper.getActiveActivity();
        if (config == null) {
            // 无活动配置，返回默认关闭状态
            return new FlashInfo(false, 0, false, "10:00", "23:59");
        }

        // 1. 查询用户今日是否已领取
        LambdaQueryWrapper<FlashGrabRecord> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(FlashGrabRecord::getUserId, userId)
                .eq(FlashGrabRecord::getActivityId, config.getId())
                .eq(FlashGrabRecord::getGrabDate, today);
        Long count = grabRecordMapper.selectCount(wrapper);
        boolean grabbed = count > 0;

        // 2. 从 Redis 获取剩余名额
        String quotaKey = QUOTA_KEY_PREFIX + today;
        String remainingStr = redisTemplate.opsForValue().get(quotaKey);
        Integer remaining;
        if (remainingStr == null) {
            // 缓存未初始化，从数据库取配置（但注意预热任务会在活动前写入，兜底用配置值）
            remaining = config.getTotalQuota();
        } else {
            remaining = Integer.parseInt(remainingStr);
        }

        // 3. 判断是否在活动时间内
        LocalTime now = LocalTime.now();
        LocalTime start = config.getStartTime();
        LocalTime end = config.getEndTime();
        boolean isActive = now.isAfter(start) && now.isBefore(end) || now.equals(start);

        FlashInfo info = new FlashInfo();
        info.setGrabbed(grabbed);
        info.setRemaining(remaining);
        info.setIsActive(isActive);
        info.setStartTime(start.format(DateTimeFormatter.ofPattern("HH:mm")));
        info.setEndTime(end.format(DateTimeFormatter.ofPattern("HH:mm")));
        return info;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public FlashInfo grab(Long userId) {
        LocalDate today = LocalDate.now();

        // ========== 1. 获取活动配置 ==========
        FlashActivityConfig config = configMapper.getActiveActivity();
        if (config == null) {
            throw new BusinessException("当前没有进行中的活动");
        }

        // ========== 2. 校验活动时间 ==========
        LocalTime now = LocalTime.now();
        LocalTime start = config.getStartTime();
        LocalTime end = config.getEndTime();
        if (now.isBefore(start) || now.isAfter(end)) {
            throw new BusinessException("活动还未开始或已结束");
        }

        // ========== 3. 分布式锁（按日期+活动ID） ==========
        String lockKey = "flash:lock:" + today + ":" + config.getId();
        RLock lock = redissonClient.getLock(lockKey);
        try {
            // 尝试加锁，等待3秒，锁有效期10秒（看门狗会自动续期）
            if (!lock.tryLock(3, 10, TimeUnit.SECONDS)) {
                throw new BusinessException("系统繁忙，请稍后重试");
            }

            // ========== 4. 检查用户今日是否已领取（MySQL查一次，防止重复） ==========
            LambdaQueryWrapper<FlashGrabRecord> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(FlashGrabRecord::getUserId, userId)
                    .eq(FlashGrabRecord::getActivityId, config.getId())
                    .eq(FlashGrabRecord::getGrabDate, today);
            Long count = grabRecordMapper.selectCount(wrapper);
            if (count > 0) {
                throw new BusinessException("今日已领取");
            }

            // ========== 5. Redis 原子扣减库存 ==========
            String quotaKey = QUOTA_KEY_PREFIX + today;
            // 如果缓存不存在，先初始化（可能预热未执行或缓存被清）
            if (Boolean.FALSE.equals(redisTemplate.hasKey(quotaKey))) {
                // 用分布式锁保护初始化，防止并发初始化
                RLock initLock = redissonClient.getLock("flash:init:" + today);
                initLock.lock();
                try {
                    if (Boolean.FALSE.equals(redisTemplate.hasKey(quotaKey))) {
                        redisTemplate.opsForValue().set(quotaKey, String.valueOf(config.getTotalQuota()));
                    }
                } finally {
                    initLock.unlock();
                }
            }

            Long remaining = redisTemplate.opsForValue().decrement(quotaKey);
            if (remaining < 0) {
                // 超卖了，回滚
                redisTemplate.opsForValue().increment(quotaKey);
                throw new BusinessException ("名额已领完，下次早点来！");
            }

            // ========== 6. 插入领取记录 + 更新用户余额（MySQL事务） ==========
            // 6.1 插入领取记录
            FlashGrabRecord record = new FlashGrabRecord();
            record.setUserId(userId);
            record.setActivityId(config.getId());
            record.setGrabDate(today);
            record.setCoinGained(config.getCoinAmount());
            try {
                grabRecordMapper.insert(record);
            } catch (DuplicateKeyException e) {
                // 唯一索引冲突，说明同一用户同一活动同一天已存在记录（极少数并发情况）
                // 回滚 Redis 库存（加回去）
                redisTemplate.opsForValue().increment(quotaKey);
                throw new BusinessException ("您已领取过，不能重复领取");
            }

            // 6.2 更新用户金币余额
            UserCoin uc = userCoinMapper.selectById(userId);
            if (uc == null) {
                // 初始化用户资产
                uc = new UserCoin();
                uc.setUserId(userId);
                uc.setCoinBalance(0);
                uc.setCashBalance(BigDecimal.ZERO);
                uc.setTotalEarnedCoin(0);
                uc.setTotalWithdrawnCash(BigDecimal.ZERO);
                userCoinMapper.insert(uc);
            }
            int oldCoin = uc.getCoinBalance();
            int newCoin = oldCoin + config.getCoinAmount();
            uc.setCoinBalance(newCoin);
            uc.setTotalEarnedCoin(uc.getTotalEarnedCoin() + config.getCoinAmount());
            userCoinMapper.updateById(uc);

            // 6.3 插入收益流水
            EarningsDetail detail = new EarningsDetail();
            detail.setUserId(userId);
            detail.setAssetType("coin");
            detail.setChangeType("flash");
            detail.setAmount(BigDecimal.valueOf(config.getCoinAmount()));
            detail.setBalanceAfter(BigDecimal.valueOf(newCoin));
            detail.setSourceId(record.getId());
            detail.setSourceType("flash");
            detail.setDescription("限时领金币");
            earningsDetailMapper.insert(detail);

            log.info("限时领成功：用户 {}, 获得 {} 金币, 剩余名额 {}", userId, config.getCoinAmount(), remaining);

            // ========== 7. 返回最新状态 ==========
            FlashInfo info = new FlashInfo();
            info.setGrabbed(true);
            info.setRemaining(remaining.intValue());
            info.setIsActive(true);
            info.setStartTime(start.format(DateTimeFormatter.ofPattern("HH:mm")));
            info.setEndTime(end.format(DateTimeFormatter.ofPattern("HH:mm")));
            return info;

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new BusinessException("系统异常，请稍后重试");
        } finally {
            if (lock.isHeldByCurrentThread()) {
                lock.unlock();
            }
        }
    }
}