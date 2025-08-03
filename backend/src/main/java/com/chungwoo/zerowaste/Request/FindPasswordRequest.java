package com.chungwoo.zerowaste.Request;

import lombok.Data;

@Data
public class FindPasswordRequest {
    private String name;
    private String emailId;
    private String phoneNumber;
    private String verificationCode;
}
