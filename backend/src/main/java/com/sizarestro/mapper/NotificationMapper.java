package com.sizarestro.mapper;

import com.sizarestro.dto.NotificationResponse;
import com.sizarestro.entity.Notification;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface NotificationMapper {
    @Mapping(target = "bookingId", source = "booking.id")
    NotificationResponse toResponse(Notification notification);
}
