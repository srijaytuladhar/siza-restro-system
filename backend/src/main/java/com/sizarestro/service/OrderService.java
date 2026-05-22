package com.sizarestro.service;

import com.sizarestro.dto.OrderItemRequest;
import com.sizarestro.dto.OrderItemResponse;
import com.sizarestro.dto.OrderRequest;
import com.sizarestro.dto.OrderResponse;
import com.sizarestro.entity.*;
import com.sizarestro.exception.BadRequestException;
import com.sizarestro.exception.ResourceNotFoundException;
import com.sizarestro.repository.BookingRepository;
import com.sizarestro.repository.MenuItemRepository;
import com.sizarestro.repository.OrderRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderService {

    private final OrderRepository orderRepository;
    private final BookingRepository bookingRepository;
    private final MenuItemRepository menuItemRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final NotificationService notificationService;

    @Transactional
    public OrderResponse placeOrder(OrderRequest orderRequest) {
        log.info("Placing new order for bookingId: {}", orderRequest.getBookingId());

        Booking booking = bookingRepository.findByIdAndStatus(orderRequest.getBookingId(), BookingStatus.ACTIVE)
                .orElseThrow(() -> new BadRequestException("Active booking not found for ID: " + orderRequest.getBookingId()));

        if (orderRequest.getItems() == null || orderRequest.getItems().isEmpty()) {
            throw new BadRequestException("Order must contain at least one item.");
        }

        Order order = new Order();
        order.setBooking(booking);
        order.setStatus(OrderStatus.WAITING);
        order.setSpecialInstructions(orderRequest.getSpecialInstructions());

        BigDecimal totalAmount = BigDecimal.ZERO;
        List<OrderItem> orderItems = new ArrayList<>();

        for (OrderItemRequest itemRequest : orderRequest.getItems()) {
            MenuItem menuItem = menuItemRepository.findById(itemRequest.getMenuItemId())
                    .orElseThrow(() -> new ResourceNotFoundException("Menu item not found with id: " + itemRequest.getMenuItemId()));

            if (!menuItem.isAvailable()) {
                throw new BadRequestException("Menu item '" + menuItem.getName() + "' is currently unavailable.");
            }

            if (itemRequest.getQuantity() <= 0) {
                throw new BadRequestException("Quantity must be greater than zero for menu item: " + menuItem.getName());
            }

            OrderItem orderItem = OrderItem.builder()
                    .order(order)
                    .menuItem(menuItem)
                    .quantity(itemRequest.getQuantity())
                    .price(menuItem.getPrice())
                    .build();

            orderItems.add(orderItem);

            BigDecimal itemTotal = menuItem.getPrice().multiply(BigDecimal.valueOf(itemRequest.getQuantity()));
            totalAmount = totalAmount.add(itemTotal);
        }

        order.setItems(orderItems);
        order.setTotalAmount(totalAmount);

        Order savedOrder = orderRepository.save(order);
        log.info("Order placed successfully. Order ID: {}, Total Amount: {}", savedOrder.getId(), totalAmount);

        OrderResponse response = mapToResponse(savedOrder);
        
        // Broadcast new order to WebSocket STOMP topic
        messagingTemplate.convertAndSend("/topic/orders", response);
        messagingTemplate.convertAndSend("/topic/booking/" + response.getBookingId(), response);

        return response;
    }

    public OrderResponse getOrder(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));
        return mapToResponse(order);
    }

    public List<OrderResponse> getAllOrders() {
        log.info("Fetching all orders");
        return orderRepository.findAll().stream()
                .map(this::mapToResponse)
                .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
                .collect(Collectors.toList());
    }

    public List<OrderResponse> getOrdersByBooking(Long bookingId) {
        log.info("Fetching orders for bookingId: {}", bookingId);
        List<Order> orders = orderRepository.findByBookingId(bookingId);
        return orders.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public OrderResponse updateOrderStatus(Long orderId, OrderStatus status) {
        log.info("Updating status of orderId: {} to {}", orderId, status);

        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));

        order.setStatus(status);
        Order updatedOrder = orderRepository.save(order);

        OrderResponse response = mapToResponse(updatedOrder);

        // Send notification depending on the new status
        try {
            Long bookingId = order.getBooking().getId();
            String tableNum = order.getBooking().getTable().getTableNumber();
            switch (status) {
                case ACCEPTED:
                    notificationService.sendNotification(bookingId, "Order Accepted", "Your order for Table " + tableNum + " has been accepted.", NotificationType.ORDER_ACCEPTED);
                    break;
                case PREPARING:
                    notificationService.sendNotification(bookingId, "Preparing Food", "The kitchen has started preparing your order for Table " + tableNum + ".", NotificationType.FOOD_PREPARING);
                    break;
                case READY:
                    notificationService.sendNotification(bookingId, "Food Ready", "Your food for Table " + tableNum + " is ready!", NotificationType.FOOD_READY);
                    break;
                case SERVED:
                    notificationService.sendNotification(bookingId, "Order Served", "Your order has been served to Table " + tableNum + ". Enjoy!", NotificationType.ORDER_SERVED);
                    break;
                default:
                    break;
            }
        } catch (Exception e) {
            log.error("Failed to send notification for order status change", e);
        }

        // Broadcast status update to WebSocket STOMP topic
        messagingTemplate.convertAndSend("/topic/orders", response);
        messagingTemplate.convertAndSend("/topic/booking/" + response.getBookingId(), response);

        return response;
    }

    private OrderResponse mapToResponse(Order order) {
        List<OrderItemResponse> itemResponses = order.getItems().stream()
                .map(item -> OrderItemResponse.builder()
                        .id(item.getId())
                        .menuItemId(item.getMenuItem().getId())
                        .menuItemName(item.getMenuItem().getName())
                        .price(item.getPrice())
                        .quantity(item.getQuantity())
                        .build())
                .collect(Collectors.toList());

        return OrderResponse.builder()
                .id(order.getId())
                .bookingId(order.getBooking().getId())
                .tableNumber(order.getBooking().getTable().getTableNumber())
                .status(order.getStatus())
                .totalAmount(order.getTotalAmount())
                .createdAt(order.getCreatedAt())
                .items(itemResponses)
                .specialInstructions(order.getSpecialInstructions())
                .paymentStatus(order.getPayment() != null ? order.getPayment().getStatus().name() : "PENDING")
                .paymentMethod(order.getPayment() != null ? order.getPayment().getPaymentMethod().name() : null)
                .build();
    }
}
