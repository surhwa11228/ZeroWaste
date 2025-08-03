package com.chungwoo.zerowaste.auth.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.Date;

@Data
@AllArgsConstructor
public class RefreshTokenSaveRequest {
    private String uid;
    private String refreshToken;
    private Date expiration;
}
