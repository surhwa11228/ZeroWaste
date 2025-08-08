package com.chungwoo.zerowaste.exception.exceptions;

import org.springframework.http.HttpStatus;

public class TokenInvalidException extends BusinessException{
    public TokenInvalidException(String message) {
        super(HttpStatus.UNAUTHORIZED, message);
    }
}
