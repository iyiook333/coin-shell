package com.xyxy.coinshell.service;

import com.xyxy.coinshell.entity.dto.BillParseResponse;
import com.xyxy.coinshell.entity.dto.HistoryMessage;

import java.util.List;

public interface AIService {
    BillParseResponse parseNaturalLanguage(String text,String sessionId,Long userId);
    List<HistoryMessage> getHistory(Long userId, String sessionId);
}
