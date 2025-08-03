package com.chungwoo.zerowaste.Request;

import lombok.Data;

@Data
public class PhoneVerificationRequest {
    private String phoneNumber;
    private String verificationCode;
}
