package com.xyxy.coinshell.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.xyxy.coinshell.entity.po.AccountPo;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AccountMapper extends BaseMapper<AccountPo> {
}
