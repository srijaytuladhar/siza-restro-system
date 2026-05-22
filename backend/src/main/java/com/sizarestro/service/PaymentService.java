package com.sizarestro.service;

import com.sizarestro.dto.PaymentRequest;
import com.sizarestro.dto.PaymentResponse;
import com.sizarestro.entity.*;
import com.sizarestro.exception.BadRequestException;
import com.sizarestro.exception.ResourceNotFoundException;
import com.sizarestro.mapper.PaymentMapper;
import com.sizarestro.repository.BookingRepository;
import com.sizarestro.repository.OrderRepository;
import com.sizarestro.repository.PaymentRepository;
import com.sizarestro.repository.TableRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final BookingRepository bookingRepository;
    private final TableRepository tableRepository;
    private final PaymentMapper paymentMapper;
    private final SimpMessagingTemplate messagingTemplate;

    @Transactional
    public PaymentResponse processPayment(PaymentRequest request) {
        log.info("Processing payment for orderId: {}, method: {}, amount: {}", 
                request.getOrderId(), request.getPaymentMethod(), request.getAmount());

        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + request.getOrderId()));

        if (paymentRepository.findByOrderId(request.getOrderId()).isPresent()) {
            throw new BadRequestException("Order " + request.getOrderId() + " has already been paid/processed.");
        }

        Payment payment = Payment.builder()
                .order(order)
                .paymentMethod(request.getPaymentMethod())
                .status(PaymentStatus.PAID)
                .amount(request.getAmount())
                .build();

        Payment savedPayment = paymentRepository.save(payment);
        order.setPayment(savedPayment);
        orderRepository.save(order);

        // Release table and close booking session on successful payment
        Booking booking = order.getBooking();
        if (booking != null && booking.getStatus() == BookingStatus.ACTIVE) {
            booking.setStatus(BookingStatus.CLOSED);
            bookingRepository.save(booking);
            log.info("Closed active booking {} for order {}", booking.getId(), order.getId());

            TableEntity table = booking.getTable();
            if (table != null) {
                table.setStatus(TableStatus.AVAILABLE);
                tableRepository.save(table);
                log.info("Released table {} (Number: {})", table.getId(), table.getTableNumber());
                messagingTemplate.convertAndSend("/topic/tables", java.util.Collections.singletonMap("status", "updated"));
            }
        }

        log.info("Payment processed successfully. Payment ID: {}", savedPayment.getId());

        PaymentResponse response = paymentMapper.toResponse(savedPayment);

        // Broadcast payment success to STOMP topics
        messagingTemplate.convertAndSend("/topic/payments", response);
        messagingTemplate.convertAndSend("/topic/booking/" + order.getBooking().getId() + "/payment", response);
        
        // Also broadcast updated order status
        messagingTemplate.convertAndSend("/topic/orders", response); // notify admin orders change

        return response;
    }

    public PaymentResponse getPaymentByOrderId(Long orderId) {
        Payment payment = paymentRepository.findByOrderId(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Payment not found for orderId: " + orderId));
        return paymentMapper.toResponse(payment);
    }
}
