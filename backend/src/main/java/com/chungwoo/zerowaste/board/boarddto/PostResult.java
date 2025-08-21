package com.chungwoo.zerowaste.board.boarddto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
public class PostResult {
    private String postId;
    private String postUri;

    public PostResult(String postId, String boardName) {
        this.postId = postId;
        this.postUri = "/api/board/" +  boardName + "/" + postId;
    }
}
