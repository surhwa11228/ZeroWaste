package com.chungwoo.zerowaste.exception.exceptions;

import org.springframework.http.HttpStatus;

public class ReportSearchFailedException extends BusinessException {
    public ReportSearchFailedException(String message, Throwable cause) {
        super(HttpStatus.INTERNAL_SERVER_ERROR, message, cause);
    }
}
