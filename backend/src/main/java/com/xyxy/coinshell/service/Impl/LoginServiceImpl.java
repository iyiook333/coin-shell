package com.xyxy.coinshell.service.Impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.lang.UUID;
import cn.hutool.core.util.RandomUtil;
import cn.hutool.core.util.StrUtil;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.RedisConstant;
import com.xyxy.coinshell.common.utils.RegexUtils;
import com.xyxy.coinshell.entity.dto.LoginDto;
import com.xyxy.coinshell.entity.po.LoginPo;
import com.xyxy.coinshell.entity.vo.LoginVo;
import com.xyxy.coinshell.entity.vo.UserStats;
import com.xyxy.coinshell.mapper.LoginMapper;
import com.xyxy.coinshell.mapper.SignRecordMapper;
import com.xyxy.coinshell.mapper.UserCoinMapper;
import com.xyxy.coinshell.service.LoginService;
import jakarta.servlet.http.HttpSession;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import static com.xyxy.coinshell.common.utils.RedisConstant.*;
import static com.xyxy.coinshell.common.utils.constant.USER_NAME_CONSTANT;

@Slf4j
@Service
public class LoginServiceImpl extends ServiceImpl<LoginMapper, LoginPo> implements LoginService {

    @Autowired
    private StringRedisTemplate stringRedisTemplate;

    @Autowired
    private UserCoinMapper userCoinMapper;

    @Autowired
    private SignRecordMapper signRecordMapper;

    @Override
    public Result<String> sendCode(String phone) {
        //1.校验手机号
        if (!RegexUtils.isPhoneValid(phone)){
            //2.如果不符合，返回错误
            return Result.fail("手机号格式错误");
        }
        //3.如果符合，生成验证码
        String code = RandomUtil.randomNumbers(6);
        //4.保存验证码到redis
        stringRedisTemplate.opsForValue().set(LOGIN_CODE_KEY+phone,code,LOGIN_CODE_TTL,TimeUnit.MINUTES);
        //5.发送验证码
        log.debug("发送短信验证码成功，验证码：{}",code);
        //6.返回结果
        return Result.success("发送成功");
    }

    @Override
    public Result<String> login(LoginDto dto) {
        String phone = dto.getPhone();
        //1.校验手机号
        if (!RegexUtils.isPhoneValid(phone)){
            //1.1.如果不符合，返回错误
            return Result.fail("手机号格式错误");
        }
        //2.校验验证码,从redis获取
        String code = stringRedisTemplate.opsForValue().get(LOGIN_CODE_KEY + phone);
        log.debug("验证码：{}",code);
        String dtoCode = dto.getCode();
        log.debug("用户输入的验证码：{}",dtoCode);
        if (code == null || !code.equals(dtoCode)){
            //3.不一致，返回错误
            return Result.fail("验证码错误");
        }
        //4.一致，根据手机号查询用户 select * from user where phone = ?
        //4.1 一致，校验通过，删除验证码（防止重复使用）
        stringRedisTemplate.delete(LOGIN_CODE_KEY + phone);
        LoginPo loginPo = query().eq("phone", phone).one();
        //5.判断用户是否存在
        if (loginPo == null){
            //6.不存在，创建新用户并保存
            loginPo = createUserWithPhone(phone);
        }

        //  7.保存用户到 redis
        //  7.1随机生成token,作为登录令牌
        String token = UUID.randomUUID().toString();
        //  7.2将LoginVo转为hash存储
        LoginVo loginVo = new LoginVo(loginPo.getId(),loginPo.getPhone(), loginPo.getUsername());
        Map<String, String> userMap = new HashMap<>();
        userMap.put("id", String.valueOf(loginVo.getId()));
        userMap.put("phone", loginVo.getPhone());
        userMap.put("username", loginVo.getUsername());
        //  7.3存储
        stringRedisTemplate.opsForHash().putAll(LOGIN_TOKEN_KEY+token,userMap);
        stringRedisTemplate.expire(LOGIN_TOKEN_KEY+token,LOGIN_TOKEN_TTL,TimeUnit.MINUTES);
        //  8.返回token
        return Result.success(token);
    }

    @Override
    public Result<String> logout(String token) {
        // 1. 校验 Token 是否存在
        if (StrUtil.isBlank(token)) {
            return Result.fail("Token 不能为空");
        }

        // 2. 删除 Redis 中的 Token 记录
        String redisKey = RedisConstant.LOGIN_TOKEN_KEY + token;
        Boolean deleted = stringRedisTemplate.delete(redisKey);
        log.debug(String.valueOf(deleted));
        if (Boolean.TRUE.equals(deleted)) {
            return Result.success("退出成功");
        } else {
            // 即使 Redis 里没有记录，也返回成功（幂等性设计）
            // 因为前端可能重复调用，或者 Token 已经过期
            return Result.success("退出成功");
        }
    }

    @Override
    public Result<UserStats> getUserStats(Long userId) {
        UserStats stats = new UserStats();

        // 1. 累计收益（元） = total_earned_coin / 100
        Integer totalEarnedCoin = userCoinMapper.getTotalEarnedCoinByUserId(userId);
        stats.setTotalEarnings(totalEarnedCoin == null ? 0.0 : totalEarnedCoin / 100.0);

        // 2. 完成任务数（暂未实现任务表，返回 0）
        stats.setCompletedTasks(0);

        // 3. 连续签到天数
        LocalDate lastSign = signRecordMapper.getLastSignDate(userId);
        if (lastSign == null) {
            stats.setConsecutiveSignIns(0);
        } else {
            // 调用原有的方法，但传入最近签到日期作为“基准日期”
            Integer consecutive = signRecordMapper.getConsecutiveSignDays(userId, lastSign);
            stats.setConsecutiveSignIns(consecutive == null ? 0 : consecutive);
        }

        return Result.success(stats);
    }

    private LoginPo createUserWithPhone(String phone) {
        //1.创建用户
        LoginPo loginPo = new LoginPo();
        loginPo.setPhone(phone);
        loginPo.setUsername(USER_NAME_CONSTANT+RandomUtil.randomString(10));
        //2.保存用户
        save(loginPo);
        return loginPo;
    }
}
