package com.chungwoo.zerowaste.Request;

import lombok.Data;

@Data
public class LoginRequest {
    private String emailId;
    private String password;
}