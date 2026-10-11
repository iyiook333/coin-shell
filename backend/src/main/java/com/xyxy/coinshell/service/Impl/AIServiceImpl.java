package com.xyxy.coinshell.service.Impl;

import com.xyxy.coinshell.entity.dto.BillParseRequest;
import com.xyxy.coinshell.entity.dto.BillParseResponse;
import com.xyxy.coinshell.entity.dto.HistoryMessage;
import com.xyxy.coinshell.service.AIService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

@Service
@Slf4j
public class AIServiceImpl implements AIService {

    @Value("${ai.service.url}")
    private String aiServiceUrl;

    @Autowired
    private RestTemplate restTemplate;

    @Override
    public BillParseResponse parseNaturalLanguage(String text, String sessionId, Long userId) {
        // 构建请求URL
        String url = aiServiceUrl + "/ai/parse";
        // 创建请求对象
        BillParseRequest request = new BillParseRequest();
        // 设置请求参数
        request.setText(text);
        // 设置会话ID
        request.setSessionId(sessionId);
        // 设置用户ID
        request.setUserId(userId);
        try {
            // 调用 AI 服务进行解析
            log.info("调用 AI 服务解析：text={}, sessionId={}", text, sessionId);
            ResponseEntity<BillParseResponse> response = restTemplate.postForEntity(
                    url, request, BillParseResponse.class
            );
            // 获取解析结果
            // 获取响应体
            BillParseResponse result = response.getBody();
            // 如果结果不为空，记录解析结果
            if (result != null) {
                log.info("AI 解析结果：金额={}, 分类={}, 备注={}",
                        result.getAmount(), result.getCategory(), result.getNote());
            }
            return result;
        } catch (Exception e) {
            log.error("AI 服务调用失败", e);
            throw new RuntimeException("AI 解析失败，请稍后重试");
        }
    }

    @Override
    public List<HistoryMessage> getHistory(Long userId,String sessionId) {
        // 构建请求URL
        String url = aiServiceUrl + "/history/" + sessionId + "?user_id=" + userId;
        try {
            //RestTemplate 自动反序列化为 HistoryMessage[]
            // 使用 RestTemplate 发起 GET 请求
            HistoryMessage[] historyArray = restTemplate.getForObject(url, HistoryMessage[].class);
            // 将数组转换为列表
            return historyArray != null ? Arrays.asList(historyArray) : Collections.emptyList();
        } catch (Exception e) {
            // 获取历史失败
            log.error("获取历史失败: sessionId={}, error={}", sessionId, e.getMessage());
            // 返回空列表
            return Collections.emptyList();
        }
    }

}