package com.xyxy.coinshell.event;

import lombok.Getter;
import org.springframework.context.ApplicationEvent;

import java.time.LocalDate;

@Getter
public class SignEvent extends ApplicationEvent {
    private final Long userId;
    private final LocalDate signDate;

    public SignEvent(Object source, Long userId, LocalDate signDate) {
        super(source);
        this.userId = userId;
        this.signDate = signDate;
    }
}