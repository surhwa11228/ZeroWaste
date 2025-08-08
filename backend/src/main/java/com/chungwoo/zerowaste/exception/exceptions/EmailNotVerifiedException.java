package com.chungwoo.zerowaste.exception.exceptions;

import org.springframework.http.HttpStatus;

public class EmailNotVerifiedException extends BusinessException{
    public EmailNotVerifiedException(String message) {
        super(HttpStatus.FORBIDDEN, message, new Throwable());
    }
}
