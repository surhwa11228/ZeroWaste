package com.chungwoo.zerowaste.auth.controller;

import com.chungwoo.zerowaste.api.ApiResponse;
import com.chungwoo.zerowaste.auth.JwtProvider;
import com.chungwoo.zerowaste.auth.dto.AccessTokenResponse;
import com.chungwoo.zerowaste.auth.dto.RefreshRequest;
import com.chungwoo.zerowaste.auth.dto.LoginResponse;
import com.chungwoo.zerowaste.auth.sevice.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(HttpServletRequest request) {
        log.debug("authorization {}", request.getHeader("Authorization"));

        LoginResponse loginResponse = authService.handleLogin(request);

        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(loginResponse));

    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AccessTokenResponse>> refresh(@RequestBody @Valid RefreshRequest request) {
        AccessTokenResponse newTokens = authService.refresh(request.getRefreshToken());
        return ResponseEntity.status(HttpStatus.OK)
                .body(ApiResponse.success(newTokens));
    }

}

