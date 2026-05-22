package com.sizarestro.mapper;

import com.sizarestro.dto.MenuCategoryRequest;
import com.sizarestro.dto.MenuCategoryResponse;
import com.sizarestro.entity.MenuCategory;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface MenuCategoryMapper {
    MenuCategoryResponse toResponse(MenuCategory category);
    
    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    MenuCategory toEntity(MenuCategoryRequest request);
}
