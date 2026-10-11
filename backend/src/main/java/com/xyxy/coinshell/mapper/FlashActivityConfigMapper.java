package com.xyxy.coinshell.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.xyxy.coinshell.entity.po.FlashActivityConfig;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface FlashActivityConfigMapper extends BaseMapper<FlashActivityConfig> {

    @Select("SELECT * FROM flash_activity_config WHERE is_active = 1 ORDER BY id DESC LIMIT 1")
    FlashActivityConfig getActiveActivity();
}