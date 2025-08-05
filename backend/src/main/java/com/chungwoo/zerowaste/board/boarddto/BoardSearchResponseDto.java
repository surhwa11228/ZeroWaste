package com.chungwoo.zerowaste.board.boarddto;

import lombok.*;
import java.util.Date;

/**
 * 게시글 목록/검색 응답 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BoardSearchResponseDto {
    private String id;
    private String title;
    private String content;
    private String category;
    private String scope;
    private String imageUrl;
    private Date createdAt;   // Date로 변경
    private boolean pinned;
    private String userId;
}
