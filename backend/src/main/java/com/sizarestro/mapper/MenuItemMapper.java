package com.sizarestro.mapper;

import com.sizarestro.dto.MenuItemRequest;
import com.sizarestro.dto.MenuItemResponse;
import com.sizarestro.entity.MenuItem;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface MenuItemMapper {
    @Mapping(target = "categoryId", source = "category.id")
    @Mapping(target = "categoryName", source = "category.name")
    MenuItemResponse toResponse(MenuItem menuItem);
    
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "category", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    MenuItem toEntity(MenuItemRequest request);
}
