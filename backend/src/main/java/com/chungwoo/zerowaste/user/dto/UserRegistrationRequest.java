package com.chungwoo.zerowaste.user.dto;

import lombok.Getter;
import lombok.Setter;

import java.util.Date;

@Getter
@Setter
public class UserRegistrationRequest {
    private String emailId;
    private String name;
    private String phoneNumber;
    private String address;
    private Date birthDate;
}
