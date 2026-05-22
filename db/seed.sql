-- Seed Data for Siza Restro (MySQL)

USE siza_restro;

-- Insert Roles
INSERT IGNORE INTO roles (id, name) VALUES
(1, 'ROLE_ADMIN'),
(2, 'ROLE_STAFF'),
(3, 'ROLE_CUSTOMER');

-- Insert Admin User (Password is 'admin123' BCrypt hashed)
-- BCrypt Hash: $2a$10$8.2uqJjL6Hh.ZpX0V1P2O.L5Qz8n3m6/a9z49lZl.K0b8C7H/nSXe
INSERT IGNORE INTO users (username, password, email, role_id) VALUES
('admin', '$2a$10$8.2uqJjL6Hh.ZpX0V1P2O.L5Qz8n3m6/a9z49lZl.K0b8C7H/nSXe', 'admin@sizarestro.com', 1);

-- Insert Restaurant Tables
INSERT IGNORE INTO restaurant_tables (table_number, capacity, qr_code_token, status) VALUES
('Table 1', 4, 't1-token-uuid-12345', 'AVAILABLE'),
('Table 2', 2, 't2-token-uuid-23456', 'AVAILABLE'),
('Table 3', 6, 't3-token-uuid-34567', 'AVAILABLE'),
('Table 4', 4, 't4-token-uuid-45678', 'AVAILABLE'),
('Table 5', 8, 't5-token-uuid-56789', 'AVAILABLE');

-- Insert Menu Categories
INSERT IGNORE INTO menu_categories (id, name, description) VALUES
(1, 'STARTERS', 'Delectable appetizers to kickstart your meal.'),
(2, 'MAIN_COURSE', 'Hearty and satisfying main dishes prepared by our master chefs.'),
(3, 'DRINKS', 'Refreshing cold and hot beverages, craft beers, and cocktails.'),
(4, 'DESSERTS', 'Sweet treats and decadent desserts to end your dining on a high note.');

-- Insert Menu Items
-- STARTERS (Category ID: 1)
INSERT INTO menu_items (name, description, price, category_id, is_available, image_url, estimated_prep_time) VALUES
('Crispy Spring Rolls', 'Deep-fried rolls stuffed with vegetables and glass noodles, served with sweet chili sauce.', 5.99, 1, TRUE, '', 10),
('Garlic Parmesan Chicken Wings', 'Crispy chicken wings tossed in garlic parmesan sauce, served with ranch dressing.', 8.99, 1, TRUE, '', 12),
('Paneer Tikka', 'Marinated cottage cheese cubes grilled in tandoor with onions and bell peppers.', 9.50, 1, TRUE, '', 15),
('Tomato Basil Bruschetta', 'Toasted baguette slices topped with fresh tomatoes, garlic, basil, and balsamic glaze.', 6.50, 1, TRUE, '', 8);

-- MAIN_COURSE (Category ID: 2)
INSERT INTO menu_items (name, description, price, category_id, is_available, image_url, estimated_prep_time) VALUES
('Grilled Ribeye Steak', 'Served with garlic mashed potatoes, roasted asparagus, and rosemary red wine reduction.', 24.99, 2, TRUE, '', 20),
('Chicken Fettuccine Alfredo', 'Fettuccine pasta tossed in rich parmesan cream sauce with grilled chicken breast.', 15.99, 2, TRUE, '', 15),
('Pan-Seared Salmon', 'Atlantic salmon fillet served with lemon herb quinoa and steamed broccoli.', 18.50, 2, TRUE, '', 18),
('Butter Chicken with Naan', 'Tender chicken cooked in rich tomato butter gravy, served with basmati rice and butter naan.', 16.99, 2, TRUE, '', 15),
('Vegetarian Lasagna', 'Layers of pasta sheets, fresh vegetables, ricotta, and mozzarella cheese in marinara sauce.', 14.50, 2, TRUE, '', 18);

-- DRINKS (Category ID: 3)
INSERT INTO menu_items (name, description, price, category_id, is_available, image_url, estimated_prep_time) VALUES
('Classic Mojito', 'Fresh mint, lime juice, simple syrup, white rum, and club soda.', 7.50, 3, TRUE, '', 5),
('Iced Peach Tea', 'Freshly brewed black tea infused with sweet peach syrup, served over ice.', 3.99, 3, TRUE, '', 3),
('Craft IPA Beer', 'Locally brewed India Pale Ale with citrus and piney hop notes.', 6.50, 3, TRUE, '', 3),
('Mango Lassi', 'Traditional yogurt-based drink blended with sweet mango pulp and a touch of cardamom.', 4.50, 3, TRUE, '', 4),
('Sparkling Mineral Water', 'Chilled sparkling water served with a slice of lemon or lime.', 2.99, 3, TRUE, '', 2);

-- DESSERTS (Category ID: 4)
INSERT INTO menu_items (name, description, price, category_id, is_available, image_url, estimated_prep_time) VALUES
('Warm Chocolate Lava Cake', 'Rich chocolate cake with a molten center, served with vanilla bean ice cream.', 7.99, 4, TRUE, '', 10),
('New York Cheesecake', 'Classic creamy cheesecake on a graham cracker crust, topped with strawberry compote.', 6.99, 4, TRUE, '', 5),
('Tiramisu', 'Espresso-soaked ladyfingers layered with mascarpone cream and dusted with cocoa powder.', 7.50, 4, TRUE, '', 5),
('Sizzling Brownie', 'Hot chocolate brownie served on a sizzling plate with vanilla ice cream and hot fudge.', 8.50, 4, TRUE, '', 12);
