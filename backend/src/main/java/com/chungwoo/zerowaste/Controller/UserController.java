package com.chungwoo.zerowaste.Controller;

import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.chungwoo.zerowaste.Service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    // Register a new user
    @PostMapping("/register")
    public UserDto registerUser(@RequestBody UserRegistrationRequest request) {
        try {
            return userService.registerUser(request);
        } catch (Exception e) {
            throw new RuntimeException("Registration failed: " + e.getMessage());
        }
    }

    // Verify phone number using verification code
    @PostMapping("/verifyPhone")
    public void verifyPhone(@RequestParam String phoneNumber, @RequestParam String verificationCode) {
        try {
            userService.verifyPhoneNumber(phoneNumber, verificationCode);
        } catch (Exception e) {
            throw new RuntimeException("Phone verification failed: " + e.getMessage());
        }
    }
}

