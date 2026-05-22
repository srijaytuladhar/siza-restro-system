package com.sizarestro.mapper;

import com.sizarestro.dto.UserResponse;
import com.sizarestro.entity.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface UserMapper {
    @Mapping(target = "role", source = "role.name")
    UserResponse toResponse(User user);
}
