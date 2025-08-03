package com.chungwoo.zerowaste.user.Request;

import lombok.Data;

@Data
public class LoginRequest {
    private String emailId;
    private String password;
}