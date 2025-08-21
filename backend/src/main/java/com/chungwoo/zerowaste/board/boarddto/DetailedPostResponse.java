package com.chungwoo.zerowaste.board.boarddto;

import lombok.*;
import lombok.experimental.SuperBuilder;

import java.util.List;

/**
 * 게시글 목록/검색 응답 DTO
 */
@Data
@EqualsAndHashCode(callSuper = false)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class DetailedPostResponse extends PostResponse {
    private String content;
    private String boardName;
    private String category;
    private List<String> imageUrls;
}
