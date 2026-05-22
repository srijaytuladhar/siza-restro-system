package com.sizarestro.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ScanRequest {
    private String qrCodeToken;
    private String userId; // Device ID or Guest session ID from Flutter Client
}
