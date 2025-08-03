package com.chungwoo.zerowaste.Request;

import lombok.Data;

@Data
public class FindIdRequest {
    private String name;
    private String phoneNumber;
    private String verificationCode;
}