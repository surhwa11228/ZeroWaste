package com.chungwoo.zerowaste.user.controller;

import com.chungwoo.zerowaste.api.ApiResponse;
import com.chungwoo.zerowaste.auth.dto.AuthUserDetails;
import com.chungwoo.zerowaste.user.dto.UserAdditionalInfoRequest;
import com.chungwoo.zerowaste.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PutMapping("/update")
    public ResponseEntity<ApiResponse<Void>> updateAdditionalInfo(@RequestBody @Valid UserAdditionalInfoRequest request,
                                                                  @AuthenticationPrincipal AuthUserDetails user) {

        userService.updateAdditionalInfo(request, user.getUid());

        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(null));
    }

    // 이메일 경로 파라미터는 그대로
//    @GetMapping("/info")
//    public UserDto getUserInfo(@AuthenticationPrincipal AuthUserDetails user) {
//        userService.getUserInfo(user.getUid());
//        return
//    }

}
