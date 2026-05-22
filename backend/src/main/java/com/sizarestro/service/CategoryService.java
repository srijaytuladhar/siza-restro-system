package com.sizarestro.service;

import com.sizarestro.dto.MenuCategoryRequest;
import com.sizarestro.dto.MenuCategoryResponse;
import com.sizarestro.entity.MenuCategory;
import com.sizarestro.exception.BadRequestException;
import com.sizarestro.exception.ResourceNotFoundException;
import com.sizarestro.mapper.MenuCategoryMapper;
import com.sizarestro.repository.MenuCategoryRepository;
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
public class CategoryService {

    private final MenuCategoryRepository categoryRepository;
    private final MenuCategoryMapper categoryMapper;

    @Cacheable(value = "categories")
    public List<MenuCategoryResponse> getAllCategories() {
        log.info("Fetching all categories from database (cache miss)");
        return categoryRepository.findAll().stream()
                .map(categoryMapper::toResponse)
                .collect(Collectors.toList());
    }

    public MenuCategoryResponse getCategoryById(Long id) {
        MenuCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));
        return categoryMapper.toResponse(category);
    }

    @Transactional
    @CacheEvict(value = "categories", allEntries = true)
    public MenuCategoryResponse createCategory(MenuCategoryRequest request) {
        log.info("Creating new category: {}", request.getName());
        if (categoryRepository.findByName(request.getName()).isPresent()) {
            throw new BadRequestException("Category with name '" + request.getName() + "' already exists");
        }
        MenuCategory category = categoryMapper.toEntity(request);
        MenuCategory savedCategory = categoryRepository.save(category);
        log.info("Category created successfully with ID: {}", savedCategory.getId());
        return categoryMapper.toResponse(savedCategory);
    }

    @Transactional
    @CacheEvict(value = "categories", allEntries = true)
    public MenuCategoryResponse updateCategory(Long id, MenuCategoryRequest request) {
        log.info("Updating category: {}", id);
        MenuCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));
        
        categoryRepository.findByName(request.getName()).ifPresent(existing -> {
            if (!existing.getId().equals(id)) {
                throw new BadRequestException("Category with name '" + request.getName() + "' already exists");
            }
        });

        category.setName(request.getName());
        category.setDescription(request.getDescription());
        MenuCategory updatedCategory = categoryRepository.save(category);
        return categoryMapper.toResponse(updatedCategory);
    }

    @Transactional
    @CacheEvict(value = "categories", allEntries = true)
    public void deleteCategory(Long id) {
        log.info("Deleting category: {}", id);
        MenuCategory category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found with id: " + id));
        categoryRepository.delete(category);
    }
}
