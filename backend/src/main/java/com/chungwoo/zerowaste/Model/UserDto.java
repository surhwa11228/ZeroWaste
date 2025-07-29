package com.chungwoo.zerowaste.Model;

import lombok.Data;

import java.util.Date;

@Data
public class UserDto {
    private String emailId;
    private String name;
    private String phoneNumber;
    private String address;
    private Date birthDate; // 문자열 또는 Date 타입 선택
    private boolean phoneVerified;
    private String socialProvider;
}
