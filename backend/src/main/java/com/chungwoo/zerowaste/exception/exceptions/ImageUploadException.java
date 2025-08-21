package com.chungwoo.zerowaste.exception.exceptions;

import org.springframework.http.HttpStatus;

public class ImageUploadException extends BusinessException {
    public ImageUploadException(String message, Throwable cause) {
        super(HttpStatus.INTERNAL_SERVER_ERROR, message, cause);
    }
}
