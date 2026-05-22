package com.sizarestro.repository;

import com.sizarestro.entity.MenuItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MenuItemRepository extends JpaRepository<MenuItem, Long> {
    List<MenuItem> findByIsAvailableTrue();
    List<MenuItem> findByCategoryId(Long categoryId);
    List<MenuItem> findByCategoryIdAndIsAvailableTrue(Long categoryId);
}
