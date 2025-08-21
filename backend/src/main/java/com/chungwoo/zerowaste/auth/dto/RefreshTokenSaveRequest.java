package com.chungwoo.zerowaste.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class RefreshTokenSaveRequest {
    private String uid;
    private String refreshToken;
    private Long expiration;
}
