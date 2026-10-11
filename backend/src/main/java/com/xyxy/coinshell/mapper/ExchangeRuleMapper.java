package com.xyxy.coinshell.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.xyxy.coinshell.entity.po.ExchangeRule;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface ExchangeRuleMapper extends BaseMapper<ExchangeRule> {

    @Select("SELECT * FROM exchange_rule WHERE is_active = 1 LIMIT 1")
    ExchangeRule getActiveRule();
}