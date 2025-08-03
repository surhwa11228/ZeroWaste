package com.chungwoo.zerowaste.user.dto;

import lombok.Data;

import java.util.Date;


@Data
public class PhoneVerificationDto {
    private String phoneNumber;
    private String verificationCode;
    private Date createdAt;
    private Date expiresAt;
    private boolean verified;
}

