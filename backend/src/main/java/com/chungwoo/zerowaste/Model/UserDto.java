package com.chungwoo.zerowaste.Model;

import lombok.Data;
import java.util.Date;

@Data
public class UserDto {
    private String emailId;
    private String name;
    private String phoneNumber;
    private String address;
    private Date birthDate;
    private boolean phoneVerified;
}
