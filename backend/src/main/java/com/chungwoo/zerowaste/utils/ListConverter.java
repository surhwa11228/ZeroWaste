package com.chungwoo.zerowaste.utils;

import com.google.cloud.firestore.QueryDocumentSnapshot;

import java.util.List;
import java.util.Objects;
import java.util.function.Function;

public class ListConverter {
    private ListConverter() {}

    public static <T> List<T> convertDocumentsToList(List<QueryDocumentSnapshot> documents,
                                                     Function<QueryDocumentSnapshot, T> mapper) {
        return documents.stream()
                .map(mapper)
                .filter(Objects::nonNull)
                .toList();
    }
}
