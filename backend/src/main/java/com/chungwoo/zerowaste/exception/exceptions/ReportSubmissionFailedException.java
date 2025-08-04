package com.chungwoo.zerowaste.exception.exceptions;

import org.springframework.http.HttpStatus;

public class ReportSubmissionFailedException extends BusinessException {
    public ReportSubmissionFailedException(String message, Throwable cause) {
        super(HttpStatus.INTERNAL_SERVER_ERROR, message, cause);
    }
}
