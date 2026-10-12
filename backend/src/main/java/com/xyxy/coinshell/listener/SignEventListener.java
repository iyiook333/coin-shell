package com.xyxy.coinshell.listener;

import com.xyxy.coinshell.event.SignEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.time.LocalDate;

import static com.xyxy.coinshell.common.utils.RedisConstant.REDIS_KEY_PREFIX;

@Component
@Slf4j
public class SignEventListener {

    @Autowired
    private StringRedisTemplate redisTemplate;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handleSignEvent(SignEvent event) {
        log.info("===== 收到签到事件，开始写入 Redis Bitmap =====");
        try {
            Long userId = event.getUserId();
            LocalDate today = event.getSignDate();
            int year = today.getYear();
            int dayOfYear = today.getDayOfYear() - 1;
            String key = REDIS_KEY_PREFIX + userId + ":" + year;
            // 写 Redis Bitmap，即使失败也不影响主事务
            Boolean result = redisTemplate.opsForValue().setBit(key, dayOfYear, true);
            log.info("写入结果: {}", result);  // 打印 true 或 false
            log.info("签到缓存写入成功: userId={}, date={}", userId, today);
        } catch (Exception e) {
            // 只记录日志，不影响主流程
            log.error("Redis Bitmap 写入失败，稍后由定时任务补偿", e);
        }
    }
}