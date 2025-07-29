package com.chungwoo.zerowaste.Controller;


import com.chungwoo.zerowaste.Model.UserDto;
import com.chungwoo.zerowaste.Model.UserRegistrationRequest;
import com.chungwoo.zerowaste.Service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping("/register")
    public UserDto registerUser(@RequestBody UserRegistrationRequest request) {
        return userService.registerUser(request);
    }

    /*@PostMapping("/verifyPhone")
    public void verifyPhone(@RequestParam String phoneNumber, @RequestParam String verificationCode) {
        userService.verifyPhoneNumber(phoneNumber, verificationCode);
    }*/
}
