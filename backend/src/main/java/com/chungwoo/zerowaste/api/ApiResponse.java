package com.chungwoo.zerowaste.api;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ApiResponse <T> {
    private final int status;
    private final String message;
    private final T data;
    //status: 200
    //messgage: aaa
    //data: [{
    //    title: aaa
    //    content: sss


    public static <T> ApiResponse<T> success(T data){
        return new ApiResponse<>(200, "success", data);
    }

    public static <T> ApiResponse<T> created(T data){
        return new ApiResponse<>(201, "created", data);
    }

    public static <T> ApiResponse<T> noContent(){
        return new ApiResponse<>(204, "noContent", null);
    }

    public static <T> ApiResponse<T> error(int status, String message){
        return new ApiResponse<>(status, message, null);
    }

}
