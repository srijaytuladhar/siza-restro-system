package com.sizarestro.mapper;

import com.sizarestro.dto.PaymentResponse;
import com.sizarestro.entity.Payment;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface PaymentMapper {
    @Mapping(target = "orderId", source = "order.id")
    PaymentResponse toResponse(Payment payment);
}
