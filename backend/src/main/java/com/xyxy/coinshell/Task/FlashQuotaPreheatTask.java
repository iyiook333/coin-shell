package com.xyxy.coinshell.task;

import com.xyxy.coinshell.entity.po.FlashActivityConfig;
import com.xyxy.coinshell.mapper.FlashActivityConfigMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Component
@Slf4j
public class FlashQuotaPreheatTask {

    @Autowired
    private FlashActivityConfigMapper configMapper;

    @Autowired
    private StringRedisTemplate redisTemplate;

    private static final String QUOTA_KEY_PREFIX = "flash:quota:";

    /**
     * 每天 09:59:50 执行预热，将当天名额写入 Redis
     */
    @Scheduled(cron = "50 59 9 * * ?")
    public void preheatDailyQuota() {
        LocalDate today = LocalDate.now();
        String key = QUOTA_KEY_PREFIX + today;
        // 如果 key 已存在，跳过（可能已手动设置过）
        if (Boolean.TRUE.equals(redisTemplate.hasKey(key))) {
            log.info("今日名额已预热，跳过: {}", key);
            return;
        }

        FlashActivityConfig config = configMapper.getActiveActivity();
        if (config == null) {
            log.warn("未找到活跃活动，无法预热名额");
            return;
        }

        redisTemplate.opsForValue().set(key, String.valueOf(config.getTotalQuota()));
        log.info("限时领名额预热成功: key={}, quota={}", key, config.getTotalQuota());
    }
}