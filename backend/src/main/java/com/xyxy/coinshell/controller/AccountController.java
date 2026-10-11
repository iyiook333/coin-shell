package com.xyxy.coinshell.controller;

import com.xyxy.coinshell.common.Result;
import com.xyxy.coinshell.common.utils.LoginVoHolder;
import com.xyxy.coinshell.entity.dto.AccountDto;
import com.xyxy.coinshell.entity.dto.BillParseRequest;
import com.xyxy.coinshell.entity.dto.HistoryMessage;
import com.xyxy.coinshell.entity.vo.CategoryStatisticsVo;
import com.xyxy.coinshell.entity.vo.LoginVo;
import com.xyxy.coinshell.entity.vo.StatisticsOverviewVo;
import com.xyxy.coinshell.entity.vo.TrendStatisticsVo;
import com.xyxy.coinshell.service.AIAccountService;
import com.xyxy.coinshell.service.AccountService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/account")
public class AccountController {

    @Autowired
    private AccountService accountService;
    //=================== 以下为记账信息接口 ===================
    /**
     * 添加记账信息
     */
    @PostMapping("/add")
    public Result<String> addAccount(@RequestBody AccountDto dto) {
        System.out.println("========== 记账接口被调用了 ==========");
        System.out.println("参数：" + dto);
        //1.从threadLocal中获取当前登录用户
        LoginVo loginVo = LoginVoHolder.getLoginVo();
        Long userId = loginVo.getId();
        //2.调用service层添加记账信息
        accountService.addAccount(userId,dto);
        //3.返回结果
        return Result.success("添加记账信息成功");
    }
    /**
     * 分页查询记账信息
     */
    @GetMapping("/page")
    public Result<Map<String, Object>> page(@RequestParam(defaultValue = "1") Integer page,
                                            @RequestParam(defaultValue = "20") Integer size) {
        LoginVo loginUser = LoginVoHolder.getLoginVo();
        Long userId = loginUser.getId();
        return accountService.pageByUser(userId, page, size);
    }

    /**
     * 删除记账信息
     */
    @DeleteMapping("/delete/{id}")
    public Result<String> deleteAccount(@PathVariable Long id) {
        // 1. 从 ThreadLocal 获取当前登录用户
        LoginVo loginUser = LoginVoHolder.getLoginVo();
        Long userId = loginUser.getId();
        // 2. 调用 service 层删除记账信息
        accountService.deleteAccount(userId, id);
        // 3. 返回结果
        return Result.success("删除记账信息成功");
    }


// =================== 以下为月度收支概览、分类支出占比、近7天收支趋势接口 ===================

    /**
     * 月度收支概览
     */
    @GetMapping("/statistics/overview")
    public Result<StatisticsOverviewVo> getStatisticsOverview(@RequestParam String month) {
        LoginVo loginVo = LoginVoHolder.getLoginVo();
        Long userId = loginVo.getId();
        return accountService.getStatisticsOverview(userId,month);
    }
    /**
     * 分类支出占比
     */
    @GetMapping("/statistics/category")
    public Result<List<CategoryStatisticsVo>> getCategoryStatistics(@RequestParam String month) {
        LoginVo loginVo = LoginVoHolder.getLoginVo();
        Long userId = loginVo.getId();
        return accountService.getCategoryStatistics(userId,month);
    }

    /**
     * 近7天收支趋势
     */
    @GetMapping("/statistics/trend")
    public Result<List<TrendStatisticsVo>> getStatisticsTrend() {
        LoginVo loginVo = LoginVoHolder.getLoginVo();
        Long userId = loginVo.getId();
        return accountService.getStatisticsTrend(userId);
    }



// =================== 以下为AI记账接口 ===================



    @Autowired
    private AIAccountService aiAccountService;
    /**
     * AI记账
     */
    @PostMapping("/voice")
    public Result<String> voiceAdd(@RequestBody BillParseRequest request) {
        // 1. 从 ThreadLocal 获取当前登录用户
        LoginVo loginUser = LoginVoHolder.getLoginVo();
        // 2. 调用 service 层添加记账信息
        return aiAccountService.addByVoice(loginUser.getId(), request.getText(),request.getSessionId());
    }

    @GetMapping("/history/{sessionId}")
    public Result<List<HistoryMessage>> getHistory(@PathVariable String sessionId) {
        // 1. 调用 service 层获取历史消息
        Long userId = LoginVoHolder.getLoginVo().getId();
        List<HistoryMessage> history = aiAccountService.getHistory(userId, sessionId);
        // 2. 返回结果
        return Result.success(history);
    }

}
