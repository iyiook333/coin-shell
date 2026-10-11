package com.xyxy.coinshell.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.xyxy.coinshell.entity.po.SignRecord;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.time.LocalDate;

@Mapper
public interface SignRecordMapper extends BaseMapper<SignRecord> {
    /**
     * 查询用户最近连续签到的天数（从今天开始）
     */
    @Select("SELECT COALESCE(COUNT(*), 0) FROM (" +
            "  SELECT sign_date, " +
            "         ROW_NUMBER() OVER (ORDER BY sign_date DESC) AS rn " +
            "  FROM sign_record " +
            "  WHERE user_id = #{userId} AND sign_date <= #{today} " +
            ") t " +
            "WHERE DATEDIFF(#{today}, sign_date) = rn - 1")
    Integer getConsecutiveSignDays(@Param("userId") Long userId, @Param("today") LocalDate today);


    @Select("SELECT MAX(sign_date) FROM sign_record WHERE user_id = #{userId}")
    LocalDate getLastSignDate(@Param("userId") Long userId);
}