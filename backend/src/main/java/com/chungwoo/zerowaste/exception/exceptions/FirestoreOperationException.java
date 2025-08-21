package com.chungwoo.zerowaste.exception.exceptions;

import org.springframework.http.HttpStatus;

public class FirestoreOperationException extends BusinessException {
    public FirestoreOperationException(String message, Throwable cause) {
        super(HttpStatus.INTERNAL_SERVER_ERROR, message, cause);
    }
}
