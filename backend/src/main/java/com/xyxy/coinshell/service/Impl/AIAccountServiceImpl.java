package com.xyxy.coinshell.service.Impl;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.entity.dto.BillParseResponse;
import com.xyxy.coinshell.entity.dto.AccountDto;
import com.xyxy.coinshell.entity.dto.HistoryMessage;
import com.xyxy.coinshell.service.AIAccountService;
import com.xyxy.coinshell.service.AIService;
import com.xyxy.coinshell.service.AccountService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
@Slf4j
public class AIAccountServiceImpl implements AIAccountService {

    @Autowired
    private AIService aiService;

    @Autowired
    private AccountService accountService;


    @Override
    @Transactional
    public Result<String> addByVoice(Long userId, String text,String sessionId) {
        // 1. AI 解析
        BillParseResponse parsed = aiService.parseNaturalLanguage(text, sessionId,userId);
        if (parsed == null) {
            throw new RuntimeException("AI 解析失败，请稍后重试");
        }
        // 2. 组装记账数据
        AccountDto dto = new AccountDto();
        dto.setAmount(BigDecimal.valueOf(parsed.getAmount()));
        dto.setType(parsed.getType());
        dto.setCategory(parsed.getCategory());
        dto.setNote(parsed.getNote());

        // 3. 执行记账
        accountService.addAccount(userId, dto);
        log.info("AI 记账成功：用户 {}，分类 {}，金额 {} 元", userId, parsed.getCategory(), parsed.getAmount());

        // 4. 返回结果
        String msg = String.format("记账成功：%s %.2f 元", parsed.getCategory(), parsed.getAmount());
        return Result.aiSuccess(msg, null);
    }

    @Override
    public List<HistoryMessage> getHistory(Long userId,String sessionId) {
        return aiService.getHistory(userId,sessionId);
    }
}