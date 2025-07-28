package com.chungwoo.zerowaste.Controller;


import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.chungwoo.zerowaste.Service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
public class UserController {
    @Autowired
    private UserService userService;

    @PostMapping("/register")
    public UserDto registerUser(@RequestBody UserRegistrationRequest request) {
        return userService.registerUser(request);
    }

    @PostMapping("/verifyPhone")
    public void verifyPhone(@RequestParam String phoneNumber, @RequestParam String verificationCode) {
        userService.verifyPhoneNumber(phoneNumber, verificationCode);
    }
}
