package com.chungwoo.zerowaste.exception.exceptions;

import lombok.Getter;
import org.springframework.http.HttpStatus;

@Getter
public class BusinessException extends RuntimeException {
    private final HttpStatus status;

    public BusinessException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public BusinessException(HttpStatus status, String message, Throwable cause) {
        super(message, cause);
        this.status = status;
    }
}
