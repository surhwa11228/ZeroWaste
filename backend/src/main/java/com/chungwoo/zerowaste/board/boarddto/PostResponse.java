package com.chungwoo.zerowaste.board.boarddto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

@Data
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class PostResponse {
    private String postId;
    private String title;
    private Long createdAt;
    private String uid;
    private String nickname;
}
