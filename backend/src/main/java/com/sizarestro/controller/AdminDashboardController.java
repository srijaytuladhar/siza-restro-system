package com.sizarestro.controller;

import com.sizarestro.dto.DashboardStatsResponse;
import com.sizarestro.entity.Payment;
import com.sizarestro.entity.TableStatus;
import com.sizarestro.entity.OrderItem;
import com.sizarestro.repository.OrderRepository;
import com.sizarestro.repository.TableRepository;
import com.sizarestro.repository.PaymentRepository;
import com.sizarestro.repository.OrderItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/dashboard")
@RequiredArgsConstructor
@Slf4j
public class AdminDashboardController {

    private final TableRepository tableRepository;
    private final OrderRepository orderRepository;
    private final PaymentRepository paymentRepository;
    private final OrderItemRepository orderItemRepository;

    @GetMapping
    public ResponseEntity<DashboardStatsResponse> getDashboardStats() {
        log.info("Fetching admin dashboard stats");

        List<Payment> payments = paymentRepository.findAll();
        BigDecimal totalRevenue = payments.stream()
                .map(Payment::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        long activeTablesCount = tableRepository.findAll().stream()
                .filter(t -> t.getStatus() == TableStatus.OCCUPIED)
                .count();

        long totalOrdersCount = orderRepository.count();

        // Calculate popular items from order items
        Map<String, Long> itemCounts = orderItemRepository.findAll().stream()
                .collect(Collectors.groupingBy(
                        oi -> oi.getMenuItem().getName(),
                        Collectors.summingLong(OrderItem::getQuantity)
                ));

        List<DashboardStatsResponse.PopularItemDto> popularItems = itemCounts.entrySet().stream()
                .map(entry -> DashboardStatsResponse.PopularItemDto.builder()
                        .name(entry.getKey())
                        .orderCount(entry.getValue())
                        .build())
                .sorted((a, b) -> b.getOrderCount().compareTo(a.getOrderCount()))
                .limit(5)
                .collect(Collectors.toList());

        // Calculate weekly sales (last 7 days, including today)
        DateTimeFormatter dayFormatter = DateTimeFormatter.ofPattern("EEEE");
        LocalDate today = LocalDate.now();
        List<DashboardStatsResponse.DailySalesDto> weeklySales = new ArrayList<>();
        
        for (int i = 6; i >= 0; i--) {
            LocalDate day = today.minusDays(i);
            String dayName = day.format(dayFormatter);
            
            BigDecimal dayRevenue = payments.stream()
                    .filter(p -> p.getCreatedAt() != null && p.getCreatedAt().toLocalDate().isEqual(day))
                    .map(Payment::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            
            weeklySales.add(DashboardStatsResponse.DailySalesDto.builder()
                    .date(dayName)
                    .revenue(dayRevenue)
                    .build());
        }

        DashboardStatsResponse stats = DashboardStatsResponse.builder()
                .totalRevenue(totalRevenue)
                .activeTablesCount(activeTablesCount)
                .totalOrdersCount(totalOrdersCount)
                .popularItems(popularItems)
                .weeklySales(weeklySales)
                .build();

        return ResponseEntity.ok(stats);
    }
}
