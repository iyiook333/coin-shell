// EarningsServiceImpl.java
package com.xyxy.coinshell.service.Impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.xyxy.coinshell.entity.po.EarningsDetail;
import com.xyxy.coinshell.entity.vo.EarningsDetailVO;
import com.xyxy.coinshell.mapper.EarningsDetailMapper;
import com.xyxy.coinshell.service.EarningsService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Slf4j
public class EarningsServiceImpl implements EarningsService {

    @Autowired
    private EarningsDetailMapper earningsDetailMapper;

    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Override
    public List<EarningsDetailVO> list(Long userId, String assetType, int page, int size) {
        int offset = page * size;
        LambdaQueryWrapper<EarningsDetail> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(EarningsDetail::getUserId, userId)
                .eq(EarningsDetail::getAssetType, assetType)
                .orderByDesc(EarningsDetail::getCreateTime)
                .last("LIMIT " + offset + "," + size);
        List<EarningsDetail> list = earningsDetailMapper.selectList(wrapper);
        return list.stream().map(this::convert).collect(Collectors.toList());
    }

    private EarningsDetailVO convert(EarningsDetail detail) {
        EarningsDetailVO vo = new EarningsDetailVO();
        vo.setId(detail.getId());
        // type：根据金额正负判断
        boolean income = detail.getAmount().compareTo(BigDecimal.ZERO) > 0;
        vo.setType(income ? "income" : "expense");
        // category：根据 change_type 映射中文
        String category = detail.getChangeType();
        switch (category) {
            case "sign": category = "签到"; break;
            case "flash": category = "限时领"; break;
            case "exchange_in": category = "兑换收入"; break;
            case "exchange_out": category = "兑换支出"; break;
            default: category = "其他";
        }
        vo.setCategory(category);
        vo.setAmount(detail.getAmount().abs().doubleValue());
        vo.setDesc(detail.getDescription());
        vo.setCreateTime(detail.getCreateTime().format(DATE_FORMAT));
        return vo;
    }
}