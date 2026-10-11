package com.xyxy.coinshell.entity.dto;

import lombok.Data;

@Data
public class BillParseResponse {
    private Double amount;
    private String category;
    private String note;
    private Integer type;
}