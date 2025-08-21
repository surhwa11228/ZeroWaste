package com.chungwoo.zerowaste.user.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class UserInfoResponse {
    private String email;
    private String nickname;
    private String region;
}
