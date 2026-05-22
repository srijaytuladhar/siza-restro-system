package com.sizarestro.dto;

import com.sizarestro.entity.TableStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TableResponse {
    private Long id;
    private String tableNumber;
    private Integer capacity;
    private String qrCodeToken;
    private TableStatus status;
    private String qrCodeBase64;
}
