package com.chungwoo.zerowaste.user.controller;

import com.chungwoo.zerowaste.user.dto.UserDto;
import com.chungwoo.zerowaste.user.service.UserService;
import com.chungwoo.zerowaste.user.Request.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.ExecutionException;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // 회원가입은 기존 UserRegistrationRequest 그대로
    @PostMapping(value = "/register", consumes = MediaType.APPLICATION_JSON_VALUE)
    public UserDto registerUser(@RequestBody UserRegistrationRequest req) throws ExecutionException {
        return userService.registerUser(req);
    }

    // 이메일 경로 파라미터는 그대로
    @GetMapping("/info/{emailId}")
    public UserDto getUserInfo(@PathVariable String emailId) {
        return userService.getUserInfo(emailId);
    }

    // JSON body 로 로그인 요청
    @PostMapping(value = "/login", consumes = MediaType.APPLICATION_JSON_VALUE)
    public String login(@RequestBody LoginRequest req) {
        return userService.login(
                req.getEmailId(),
                req.getPassword()
        );
    }
}
