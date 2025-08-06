package com.chungwoo.zerowaste.board.boarddto;

import lombok.*;

/**
 * 게시글 목록/검색 응답 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BoardGetResponse {
    private String id;
    private String title;
    private String content;
    private String category;
    private String scope;
    private String imageUrl;
    private Long createdAt;   // Date로 변경
    private boolean pinned;
    private String userId;
}
