package com.chungwoo.zerowaste.user.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class UserAdditionalInfoRequest {
    @NotBlank
    private String nickname;

    @NotBlank
    private String region;
}
