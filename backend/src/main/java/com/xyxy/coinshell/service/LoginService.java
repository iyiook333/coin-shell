package com.xyxy.coinshell.service;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.entity.dto.LoginDto;
import com.xyxy.coinshell.entity.vo.UserStats;

public interface LoginService {

    Result<String> sendCode(String phone);

    Result <String> login(LoginDto dto);

    Result<String> logout(String token);

    Result<UserStats> getUserStats(Long userId);
}
