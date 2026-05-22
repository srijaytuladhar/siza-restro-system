package com.sizarestro.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.math.BigDecimal;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DashboardStatsResponse {
    private BigDecimal totalRevenue;
    private Long activeTablesCount;
    private Long totalOrdersCount;
    private List<PopularItemDto> popularItems;
    private List<DailySalesDto> weeklySales;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class PopularItemDto {
        private String name;
        private Long orderCount;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class DailySalesDto {
        private String date; // e.g. "Monday", "2026-05-22"
        private BigDecimal revenue;
    }
}
