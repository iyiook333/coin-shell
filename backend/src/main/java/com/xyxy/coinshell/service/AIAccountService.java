package com.xyxy.coinshell.service;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.entity.dto.HistoryMessage;

import java.util.List;

public interface AIAccountService {
     Result<String> addByVoice(Long userId, String text,String sessionId);
     List<HistoryMessage> getHistory(Long useId,String sessionId);
}
