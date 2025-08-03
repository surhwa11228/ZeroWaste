package com.chungwoo.zerowaste.Controller;

import com.chungwoo.zerowaste.Service.PhoneVerificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/phone")
@RequiredArgsConstructor
public class PhoneVerificationController {

    private final PhoneVerificationService phoneVerificationService;

    // 전화번호 인증 코드 전송
    @PostMapping("/send")
    public void sendVerificationCode(@RequestParam String phoneNumber) {
        phoneVerificationService.sendVerificationCode(phoneNumber);
    }
}

