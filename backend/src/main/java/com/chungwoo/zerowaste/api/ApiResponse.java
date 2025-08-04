package com.chungwoo.zerowaste.api;

public class ApiResponse <T>{
    private int status;
    private String message;
    private T data;

    public ApiResponse(int status, String message, T data) {
        this.status = status;
        this.message = message;
        this.data = data;
    }

    public static <T> ApiResponse<T> success(T data){
        return new ApiResponse<>(200, "success", data);
    }

    public static <T> ApiResponse<T> created(T data){
        return new ApiResponse<>(201, "created", data);
    }

    public static <T> ApiResponse<T> noContent(T data){
        return new ApiResponse<>(204, "noContent", null);
    }

    public static <T> ApiResponse<T> error(int status, String message){
        return new ApiResponse<>(status, message, null);
    }

}
