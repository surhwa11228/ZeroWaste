package com.chungwoo.zerowaste.Controller;

import com.chungwoo.zerowaste.Model.PhoneVerificationDto;
import com.chungwoo.zerowaste.Service.PhoneVerificationService;
import com.chungwoo.zerowaste.Service.UserService;
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
    private final UserService userService;
    // 전화번호 인증 코드 전송
  /*  @PostMapping("/send")
    public void sendVerificationCode(@RequestParam String phoneNumber) {
        phoneVerificationService.sendVerificationCode(phoneNumber);
    }*/

   /* @PostMapping("/findId")
    public String findId(@RequestParam String name, @RequestParam String phoneNumber, @RequestParam String verificationCode) {
        try {
            return userService.findId(name, phoneNumber, verificationCode);
        } catch (Exception e) {
            throw new RuntimeException("Failed to find ID: " + e.getMessage());
        }
    }*/

}
