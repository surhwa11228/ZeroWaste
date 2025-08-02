package com.chungwoo.zerowaste.OAuth;

import org.springframework.context.annotation.Configuration;

//@EnableOAuth2Sso
@Configuration
public class SecurityConfig /*extends WebSecurityConfigurerAdapter*/{
    /*@Override
    protected void configure(HttpSecurity http) throws Exception {
        http
                .authorizeRequests()
                .antMatchers("/", "/login**", "/webjars/**", "/error**")
                .permitAll()
                .anyRequest()
                .authenticated();
    }*/
}
