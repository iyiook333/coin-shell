package com.xyxy.coinshell.config;

import com.xyxy.coinshell.common.Result; // 替换为你实际的 Result 类路径
import com.xyxy.coinshell.common.utils.BusinessException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice
public class WebExceptionAdvice {

    // 处理所有运行时异常
    @ExceptionHandler(RuntimeException.class)
    public Result<?> handleRuntimeException(RuntimeException e) {
        log.error("运行时异常: {}", e.getMessage(), e); // 打印完整堆栈
        return Result.fail("系统繁忙，请稍后再试"); // 返回用户友好的信息，不要暴露内部细节
    }
    @ExceptionHandler(BusinessException.class)
    public Result<?> handleBusinessException(BusinessException e) {
        log.warn("业务异常: {}", e.getMessage());
        return Result.fail(e.getCode(), e.getMessage());
    }
    @ExceptionHandler(DuplicateKeyException.class)
    public Result<?> handleDuplicateKeyException(DuplicateKeyException e) {
        log.warn("数据重复: {}", e.getMessage());
        return Result.fail("操作失败，数据已存在");
    }
    // 你还可以添加其他异常处理器，例如：
    // @ExceptionHandler(ValidationException.class)
    // public Result<?> handleValidation(ValidationException e) { ... }
}