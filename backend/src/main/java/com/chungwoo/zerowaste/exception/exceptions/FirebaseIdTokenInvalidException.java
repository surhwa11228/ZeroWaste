package com.chungwoo.zerowaste.exception.exceptions;

import org.springframework.http.HttpStatus;

public class FirebaseIdTokenInvalidException extends BusinessException {
    public FirebaseIdTokenInvalidException(String message, Throwable cause) {
        super(HttpStatus.UNAUTHORIZED, message, cause);
    }
}
