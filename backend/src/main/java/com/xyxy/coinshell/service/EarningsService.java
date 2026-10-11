// EarningsService.java
package com.xyxy.coinshell.service;

import com.xyxy.coinshell.entity.vo.EarningsDetailVO;
import java.util.List;

public interface EarningsService {
    List<EarningsDetailVO> list(Long userId, String assetType, int page, int size);
}