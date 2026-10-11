package com.xyxy.coinshell.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.xyxy.coinshell.entity.po.UserCoin;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface UserCoinMapper extends BaseMapper<UserCoin> {
    // UserCoinMapper.java
    @Select("SELECT total_earned_coin FROM user_coin WHERE user_id = #{userId}")
    Integer getTotalEarnedCoinByUserId(Long userId);
}