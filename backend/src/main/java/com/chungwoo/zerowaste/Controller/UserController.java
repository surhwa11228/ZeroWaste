package com.chungwoo.zerowaste.Controller;

import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Request.*;
import com.chungwoo.zerowaste.Service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // 회원가입은 기존 UserRegistrationRequest 그대로
    @PostMapping(value = "/register", consumes = MediaType.APPLICATION_JSON_VALUE)
    public UserDto registerUser(@RequestBody UserRegistrationRequest req) {
        return userService.registerUser(req);
    }

    // JSON body 로 전화번호+코드 받아서 검증
    @PostMapping(value = "/verifyPhone", consumes = MediaType.APPLICATION_JSON_VALUE)
    public void verifyPhone(@RequestBody PhoneVerificationRequest req) {
        userService.verifyPhoneNumber(req.getPhoneNumber(), req.getVerificationCode());
    }

    // 이메일 경로 파라미터는 그대로
    @GetMapping("/info/{emailId}")
    public UserDto getUserInfo(@PathVariable String emailId) {
        return userService.getUserInfo(emailId);
    }

    // JSON body 로 이름+전화번호+코드 받아서 아이디 찾기
    @PostMapping(value = "/findId", consumes = MediaType.APPLICATION_JSON_VALUE)
    public String findId(@RequestBody FindIdRequest req) {
        return userService.findId(
                req.getName(),
                req.getPhoneNumber(),
                req.getVerificationCode()
        );
    }

    // JSON body 로 이름+이메일+전화번호+코드 받아서 임시 비밀번호 생성
    @PostMapping(value = "/findPassword", consumes = MediaType.APPLICATION_JSON_VALUE)
    public String findPassword(@RequestBody FindPasswordRequest req) {
        return userService.findPassword(
                req.getName(),
                req.getEmailId(),
                req.getPhoneNumber(),
                req.getVerificationCode()
        );
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
