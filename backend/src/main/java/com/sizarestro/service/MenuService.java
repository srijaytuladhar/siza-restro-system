package com.sizarestro.service;

import com.sizarestro.dto.MenuItemRequest;
import com.sizarestro.dto.MenuItemResponse;
import com.sizarestro.entity.MenuCategory;
import com.sizarestro.entity.MenuItem;
import com.sizarestro.exception.ResourceNotFoundException;
import com.sizarestro.mapper.MenuItemMapper;
import com.sizarestro.repository.MenuCategoryRepository;
import com.sizarestro.repository.MenuItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MenuService {

    private final MenuItemRepository menuItemRepository;
    private final MenuCategoryRepository categoryRepository;
    private final MenuItemMapper menuItemMapper;

    @Cacheable(value = "menuItems")
    public List<MenuItemResponse> getAllMenuItems() {
        log.info("Fetching all menu items from database (cache miss)");
        return menuItemRepository.findAll().stream()
                .map(menuItemMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Cacheable(value = "menuItems", key = "'available'")
    public List<MenuItemResponse> getAvailableMenu() {
        log.info("Fetching all active menu items from database (cache miss)");
        return menuItemRepository.findByIsAvailableTrue().stream()
                .map(menuItemMapper::toResponse)
                .collect(Collectors.toList());
    }

    public MenuItemResponse getMenuItemById(Long id) {
        MenuItem menuItem = menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Menu item not found with id: " + id));
        return menuItemMapper.toResponse(menuItem);
    }

    @Transactional
    @CacheEvict(value = "menuItems", allEntries = true)
    public MenuItemResponse createMenuItem(MenuItemRequest request) {
        log.info("Creating new menu item: {}", request.getName());
        MenuCategory category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + request.getCategoryId()));

        MenuItem menuItem = menuItemMapper.toEntity(request);
        menuItem.setCategory(category);
        
        MenuItem savedItem = menuItemRepository.save(menuItem);
        log.info("Menu item created successfully with ID: {}", savedItem.getId());
        return menuItemMapper.toResponse(savedItem);
    }

    @Transactional
    @CacheEvict(value = "menuItems", allEntries = true)
    public MenuItemResponse updateMenuItem(Long id, MenuItemRequest request) {
        log.info("Updating menu item: {}", id);
        MenuItem menuItem = menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Menu item not found with id: " + id));
        
        MenuCategory category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + request.getCategoryId()));

        menuItem.setName(request.getName());
        menuItem.setDescription(request.getDescription());
        menuItem.setPrice(request.getPrice());
        menuItem.setCategory(category);
        menuItem.setAvailable(request.isAvailable());
        menuItem.setImageUrl(request.getImageUrl());
        menuItem.setEstimatedPrepTime(request.getEstimatedPrepTime());

        MenuItem updatedItem = menuItemRepository.save(menuItem);
        return menuItemMapper.toResponse(updatedItem);
    }

    @Transactional
    @CacheEvict(value = "menuItems", allEntries = true)
    public void deleteMenuItem(Long id) {
        log.info("Deleting menu item: {}", id);
        MenuItem menuItem = menuItemRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Menu item not found with id: " + id));
        menuItemRepository.delete(menuItem);
    }
}
