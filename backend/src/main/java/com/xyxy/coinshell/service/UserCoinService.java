package com.xyxy.coinshell.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.xyxy.coinshell.entity.po.UserCoin;

public interface UserCoinService extends IService<UserCoin> {
    UserCoin getOrCreate(Long userId);

}
