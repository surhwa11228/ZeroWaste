package com.chungwoo.zerowaste.Model;

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
