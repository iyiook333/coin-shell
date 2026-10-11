package com.xyxy.coinshell.service.Impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.xyxy.coinshell.entity.po.UserCoin;
import com.xyxy.coinshell.mapper.UserCoinMapper;
import com.xyxy.coinshell.service.UserCoinService;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Service
public class UserCoinServiceImpl extends ServiceImpl<UserCoinMapper, UserCoin> implements UserCoinService {

    @Override
    public UserCoin getOrCreate(Long userId) {
        UserCoin uc = getById(userId);
        if (uc == null) {
            uc = new UserCoin();
            uc.setUserId(userId);
            uc.setCoinBalance(0);
            uc.setCashBalance(BigDecimal.ZERO);
            uc.setTotalEarnedCoin(0);
            uc.setTotalWithdrawnCash(BigDecimal.ZERO);
            save(uc);
        }
        return uc;
    }

}