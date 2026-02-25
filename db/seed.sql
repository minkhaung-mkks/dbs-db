-- ─── Users ────────────────────────────────────────────────────────

INSERT INTO users (id, email, password_hash, display_name, avatar_url, bio, role, is_banned) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'admin@buildboard.com', '$2b$10$placeholder_admin_hash_will_be_set_by_seed_script__', 'Admin', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop', 'Platform administrator', 'admin', false),
  ('a0000000-0000-0000-0000-000000000002', 'alice@example.com', '$2b$10$placeholder_user1_hash_will_be_set_by_seed_script__', 'Alice Chen', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop', 'PC enthusiast and gamer', 'user', false),
  ('a0000000-0000-0000-0000-000000000003', 'bob@example.com', '$2b$10$placeholder_user2_hash_will_be_set_by_seed_script__', 'Bob Martinez', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop', 'Content creator looking for the perfect workstation', 'user', false),
  ('a0000000-0000-0000-0000-000000000004', 'techpro@example.com', '$2b$10$placeholder_build1_hash_will_be_set_by_seed_script', 'TechPro Builds', 'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=150&h=150&fit=crop', 'Professional PC builder with 10+ years experience', 'builder', false),
  ('a0000000-0000-0000-0000-000000000005', 'elite@example.com', '$2b$10$placeholder_build2_hash_will_be_set_by_seed_script', 'ElitePC Workshop', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&h=150&fit=crop', 'Custom gaming and workstation builds', 'builder', false);

-- ─── Builder Profiles ────────────────────────────────────────────

INSERT INTO builder_profiles (id, user_id, business_name, registration_number, address, website, portfolio_url, years_of_experience, specialization, avg_rating, completed_builds, is_verified) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000004', 'TechPro Builds', 'BIZ-2024-001', '123 Tech Street, San Jose, CA', 'https://techprobuilds.example.com', 'https://techprobuilds.example.com/portfolio', 10, 'Gaming PCs, Workstations', 4.50, 150, true),
  ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000005', 'ElitePC Workshop', 'BIZ-2024-002', '456 Builder Ave, Austin, TX', 'https://elitepc.example.com', NULL, 7, 'Custom Gaming, RGB Builds', 4.20, 85, true);

-- ─── Part Categories ─────────────────────────────────────────────

INSERT INTO part_categories (id, category_name, description, icon) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'CPU', 'Central Processing Unit', 'cpu'),
  ('c0000000-0000-0000-0000-000000000002', 'GPU', 'Graphics Processing Unit', 'gpu'),
  ('c0000000-0000-0000-0000-000000000003', 'Motherboard', 'Motherboard / Mainboard', 'motherboard'),
  ('c0000000-0000-0000-0000-000000000004', 'RAM', 'Memory', 'ram'),
  ('c0000000-0000-0000-0000-000000000005', 'Storage', 'SSD / HDD Storage', 'storage'),
  ('c0000000-0000-0000-0000-000000000006', 'PSU', 'Power Supply Unit', 'psu'),
  ('c0000000-0000-0000-0000-000000000007', 'Case', 'PC Case / Chassis', 'case'),
  ('c0000000-0000-0000-0000-000000000008', 'Cooling', 'CPU Cooler', 'cooling');

-- ─── Parts ───────────────────────────────────────────────────────

-- CPU (5)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'AMD Ryzen 7 7700X', 'AMD', 'Ryzen 7 7700X',
   '{"socket":"AM5","cores":8,"threads":16,"base_clock_ghz":4.5,"boost_clock_ghz":5.4,"tdp_watts":105,"integrated_graphics":true}',
   299.99, 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'AMD Ryzen 5 7600X', 'AMD', 'Ryzen 5 7600X',
   '{"socket":"AM5","cores":6,"threads":12,"base_clock_ghz":4.7,"boost_clock_ghz":5.3,"tdp_watts":105,"integrated_graphics":true}',
   199.99, 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 'Intel Core i7-13700K', 'Intel', 'Core i7-13700K',
   '{"socket":"LGA1700","cores":16,"threads":24,"base_clock_ghz":3.4,"boost_clock_ghz":5.4,"tdp_watts":125,"integrated_graphics":true}',
   349.99, 'https://images.unsplash.com/photo-1555680202-c86f0e12f086?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000001', 'Intel Core i5-13600K', 'Intel', 'Core i5-13600K',
   '{"socket":"LGA1700","cores":14,"threads":20,"base_clock_ghz":3.5,"boost_clock_ghz":5.1,"tdp_watts":125,"integrated_graphics":true}',
   264.99, 'https://images.unsplash.com/photo-1555680202-c86f0e12f086?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000001', 'AMD Ryzen 9 7950X', 'AMD', 'Ryzen 9 7950X',
   '{"socket":"AM5","cores":16,"threads":32,"base_clock_ghz":4.5,"boost_clock_ghz":5.7,"tdp_watts":170,"integrated_graphics":true}',
   549.99, 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- GPU (5)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000002', 'NVIDIA GeForce RTX 4070', 'NVIDIA', 'RTX 4070',
   '{"interface":"PCIe 4.0 x16","vram_gb":12,"vram_type":"GDDR6X","length_mm":244,"tdp_watts":200,"recommended_psu_watts":650,"slots_occupied":2.5}',
   549.99, 'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000002', 'NVIDIA GeForce RTX 4080', 'NVIDIA', 'RTX 4080',
   '{"interface":"PCIe 4.0 x16","vram_gb":16,"vram_type":"GDDR6X","length_mm":304,"tdp_watts":320,"recommended_psu_watts":750,"slots_occupied":3}',
   1099.99, 'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000002', 'AMD Radeon RX 7900 XTX', 'AMD', 'RX 7900 XTX',
   '{"interface":"PCIe 4.0 x16","vram_gb":24,"vram_type":"GDDR6","length_mm":287,"tdp_watts":355,"recommended_psu_watts":800,"slots_occupied":2.5}',
   899.99, 'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000002', 'NVIDIA GeForce RTX 4060', 'NVIDIA', 'RTX 4060',
   '{"interface":"PCIe 4.0 x16","vram_gb":8,"vram_type":"GDDR6","length_mm":240,"tdp_watts":115,"recommended_psu_watts":550,"slots_occupied":2}',
   299.99, 'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000002', 'AMD Radeon RX 7800 XT', 'AMD', 'RX 7800 XT',
   '{"interface":"PCIe 4.0 x16","vram_gb":16,"vram_type":"GDDR6","length_mm":267,"tdp_watts":263,"recommended_psu_watts":700,"slots_occupied":2.5}',
   449.99, 'https://images.unsplash.com/photo-1591488320449-011701bb6704?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- Motherboard (5)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000011', 'c0000000-0000-0000-0000-000000000003', 'MSI MAG B650 TOMAHAWK WiFi', 'MSI', 'MAG B650 TOMAHAWK WiFi',
   '{"socket":"AM5","form_factor":"ATX","chipset":"B650","ram_type":"DDR5","ram_slots":4,"max_ram_gb":128,"m2_slots":2,"pcie_x16_slots":1}',
   219.99, 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000012', 'c0000000-0000-0000-0000-000000000003', 'Gigabyte X670E AORUS Master', 'Gigabyte', 'X670E AORUS Master',
   '{"socket":"AM5","form_factor":"ATX","chipset":"X670E","ram_type":"DDR5","ram_slots":4,"max_ram_gb":128,"m2_slots":4,"pcie_x16_slots":2}',
   399.99, 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000013', 'c0000000-0000-0000-0000-000000000003', 'ASUS ROG Strix Z790-E', 'ASUS', 'ROG Strix Z790-E',
   '{"socket":"LGA1700","form_factor":"ATX","chipset":"Z790","ram_type":"DDR5","ram_slots":4,"max_ram_gb":128,"m2_slots":5,"pcie_x16_slots":2}',
   379.99, 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000014', 'c0000000-0000-0000-0000-000000000003', 'MSI MAG B660M Mortar WiFi', 'MSI', 'MAG B660M Mortar WiFi',
   '{"socket":"LGA1700","form_factor":"mATX","chipset":"B660","ram_type":"DDR5","ram_slots":2,"max_ram_gb":64,"m2_slots":2,"pcie_x16_slots":1}',
   159.99, 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000015', 'c0000000-0000-0000-0000-000000000003', 'ASUS ROG Strix B650E-I', 'ASUS', 'ROG Strix B650E-I',
   '{"socket":"AM5","form_factor":"ITX","chipset":"B650E","ram_type":"DDR5","ram_slots":2,"max_ram_gb":64,"m2_slots":2,"pcie_x16_slots":1}',
   299.99, 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- RAM (4)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000016', 'c0000000-0000-0000-0000-000000000004', 'Corsair Vengeance DDR5-6000 32GB', 'Corsair', 'Vengeance DDR5-6000 32GB (2x16GB)',
   '{"type":"DDR5","speed_mhz":6000,"capacity_gb":16,"modules":2,"total_capacity_gb":32,"cas_latency":30}',
   109.99, 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000017', 'c0000000-0000-0000-0000-000000000004', 'G.Skill Trident Z5 DDR5-6400 32GB', 'G.Skill', 'Trident Z5 DDR5-6400 32GB (2x16GB)',
   '{"type":"DDR5","speed_mhz":6400,"capacity_gb":16,"modules":2,"total_capacity_gb":32,"cas_latency":32}',
   134.99, 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000018', 'c0000000-0000-0000-0000-000000000004', 'Corsair Vengeance DDR5-5600 64GB', 'Corsair', 'Vengeance DDR5-5600 64GB (2x32GB)',
   '{"type":"DDR5","speed_mhz":5600,"capacity_gb":32,"modules":2,"total_capacity_gb":64,"cas_latency":36}',
   189.99, 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000019', 'c0000000-0000-0000-0000-000000000004', 'Kingston Fury Beast DDR5-5200 16GB', 'Kingston', 'Fury Beast DDR5-5200 16GB (2x8GB)',
   '{"type":"DDR5","speed_mhz":5200,"capacity_gb":8,"modules":2,"total_capacity_gb":16,"cas_latency":40}',
   54.99, 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- Storage (4)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000020', 'c0000000-0000-0000-0000-000000000005', 'Samsung 990 Pro 1TB', 'Samsung', '990 Pro 1TB',
   '{"type":"NVMe","interface":"M.2","capacity_gb":1000,"read_speed_mbps":7450,"write_speed_mbps":6900,"form_factor":"M.2 2280"}',
   109.99, 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000021', 'c0000000-0000-0000-0000-000000000005', 'WD Black SN850X 2TB', 'Western Digital', 'SN850X 2TB',
   '{"type":"NVMe","interface":"M.2","capacity_gb":2000,"read_speed_mbps":7300,"write_speed_mbps":6600,"form_factor":"M.2 2280"}',
   159.99, 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000022', 'c0000000-0000-0000-0000-000000000005', 'Crucial P3 Plus 1TB', 'Crucial', 'P3 Plus 1TB',
   '{"type":"NVMe","interface":"M.2","capacity_gb":1000,"read_speed_mbps":5000,"write_speed_mbps":4200,"form_factor":"M.2 2280"}',
   59.99, 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000023', 'c0000000-0000-0000-0000-000000000005', 'Samsung 870 EVO 1TB SATA', 'Samsung', '870 EVO 1TB',
   '{"type":"SATA","interface":"2.5\"","capacity_gb":1000,"read_speed_mbps":560,"write_speed_mbps":530,"form_factor":"2.5\""}',
   79.99, 'https://images.unsplash.com/photo-1597872200969-2b65d56bd16b?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- PSU (4)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000024', 'c0000000-0000-0000-0000-000000000006', 'Corsair RM850x', 'Corsair', 'RM850x',
   '{"wattage":850,"efficiency_rating":"80+ Gold","modular":"Full","form_factor":"ATX"}',
   139.99, 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000025', 'c0000000-0000-0000-0000-000000000006', 'EVGA SuperNOVA 1000 G7', 'EVGA', 'SuperNOVA 1000 G7',
   '{"wattage":1000,"efficiency_rating":"80+ Gold","modular":"Full","form_factor":"ATX"}',
   179.99, 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000026', 'c0000000-0000-0000-0000-000000000006', 'Seasonic Focus GX-750', 'Seasonic', 'Focus GX-750',
   '{"wattage":750,"efficiency_rating":"80+ Gold","modular":"Full","form_factor":"ATX"}',
   109.99, 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000027', 'c0000000-0000-0000-0000-000000000006', 'Corsair SF750 Platinum', 'Corsair', 'SF750 Platinum',
   '{"wattage":750,"efficiency_rating":"80+ Platinum","modular":"Full","form_factor":"SFX"}',
   159.99, 'https://images.unsplash.com/photo-1587202372775-e229f172b9d7?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- Case (4)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000028', 'c0000000-0000-0000-0000-000000000007', 'Corsair 4000D Airflow', 'Corsair', '4000D Airflow',
   '{"form_factor":"ATX","supported_motherboards":["ATX","mATX","ITX"],"max_gpu_length_mm":360,"max_cooler_height_mm":170,"max_psu_length_mm":180,"drive_bays_3_5":2,"drive_bays_2_5":2,"included_fans":2,"radiator_support":["120mm","240mm","280mm","360mm"]}',
   104.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000029', 'c0000000-0000-0000-0000-000000000007', 'Cooler Master NR200P', 'Cooler Master', 'NR200P',
   '{"form_factor":"ITX","supported_motherboards":["ITX"],"max_gpu_length_mm":330,"max_cooler_height_mm":155,"max_psu_length_mm":130,"drive_bays_3_5":1,"drive_bays_2_5":3,"included_fans":2,"radiator_support":["120mm","240mm","280mm"]}',
   99.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000030', 'c0000000-0000-0000-0000-000000000007', 'NZXT H7 Flow', 'NZXT', 'H7 Flow',
   '{"form_factor":"ATX","supported_motherboards":["ATX","mATX","ITX"],"max_gpu_length_mm":400,"max_cooler_height_mm":185,"max_psu_length_mm":200,"drive_bays_3_5":2,"drive_bays_2_5":2,"included_fans":2,"radiator_support":["120mm","240mm","280mm","360mm"]}',
   129.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000031', 'c0000000-0000-0000-0000-000000000007', 'Lian Li Lancool III', 'Lian Li', 'Lancool III',
   '{"form_factor":"ATX","supported_motherboards":["ATX","mATX","ITX"],"max_gpu_length_mm":420,"max_cooler_height_mm":187,"max_psu_length_mm":210,"drive_bays_3_5":4,"drive_bays_2_5":6,"included_fans":3,"radiator_support":["120mm","240mm","280mm","360mm"]}',
   149.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- Cooling (4)
INSERT INTO parts (id, category_id, name, brand, model, specifications, price, image_url, is_active, created_by) VALUES
  ('d0000000-0000-0000-0000-000000000032', 'c0000000-0000-0000-0000-000000000008', 'DeepCool AK620', 'DeepCool', 'AK620',
   '{"type":"Air","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":null,"height_mm":160,"fan_count":2,"tdp_rating_watts":260}',
   64.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000033', 'c0000000-0000-0000-0000-000000000008', 'Noctua NH-D15', 'Noctua', 'NH-D15',
   '{"type":"Air","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":null,"height_mm":165,"fan_count":2,"tdp_rating_watts":250}',
   109.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000034', 'c0000000-0000-0000-0000-000000000008', 'NZXT Kraken X63', 'NZXT', 'Kraken X63',
   '{"type":"AIO","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":280,"height_mm":null,"fan_count":2,"tdp_rating_watts":300}',
   149.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001'),
  ('d0000000-0000-0000-0000-000000000035', 'c0000000-0000-0000-0000-000000000008', 'Arctic Liquid Freezer II 360', 'Arctic', 'Liquid Freezer II 360',
   '{"type":"AIO","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":360,"height_mm":null,"fan_count":3,"tdp_rating_watts":350}',
   119.99, 'https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=300&h=300&fit=crop', true, 'a0000000-0000-0000-0000-000000000001');

-- ─── Builds ──────────────────────────────────────────────────────

INSERT INTO builds (id, creator_id, title, description, purpose, total_price, status, build_type, availability_status, image_urls, specs_summary, like_count, rating_avg, rating_count) VALUES
  ('e0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Ultimate Gaming Rig', 'High-end gaming build for 1440p gaming at max settings', 'Gaming', 1649.93, 'published', 'personal', NULL, '{"https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=600&h=400&fit=crop"}', NULL, 3, 4.50, 2),
  ('e0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'Content Creator Workstation', 'Powerful workstation for video editing and 3D rendering', 'Content Creation', 2519.93, 'published', 'personal', NULL, '{"https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=600&h=400&fit=crop"}', NULL, 1, 5.00, 1),
  ('e0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004', 'ProGamer Elite Build', 'Pre-built high-performance gaming PC ready to ship. Professionally assembled with cable management and stress testing included.', 'Gaming', 1899.93, 'published', 'showcase', 'available', '{"https://images.unsplash.com/photo-1591488320449-011701bb6704?w=600&h=400&fit=crop", "https://images.unsplash.com/photo-1587202372634-32705e3bf49c?w=600&h=400&fit=crop"}', 'Ryzen 9 7950X / RTX 4080 / 64GB DDR5 / 2TB NVMe', 5, 4.80, 3);

-- ─── Build Parts ─────────────────────────────────────────────────

-- Gaming build: R7 7700X + RTX 4070 + B650 Tomahawk + Corsair DDR5 32GB + Samsung 990 Pro + RM850x + 4000D + AK620
INSERT INTO build_parts (build_id, part_id, quantity) VALUES
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 1),
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000006', 1),
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000011', 1),
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000016', 1),
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000020', 1),
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000024', 1),
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000028', 1),
  ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000032', 1);

-- Workstation: R9 7950X + RTX 4080 + X670E AORUS + DDR5 64GB + SN850X + EVGA 1000G + H7 Flow + Arctic 360
INSERT INTO build_parts (build_id, part_id, quantity) VALUES
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000005', 1),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000007', 1),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000012', 1),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000018', 1),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000021', 1),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000025', 1),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000030', 1),
  ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000035', 1);

-- Showcase: R9 7950X + RTX 4080 + X670E AORUS + DDR5 64GB + SN850X + EVGA 1000G + Lancool III + Arctic 360
INSERT INTO build_parts (build_id, part_id, quantity) VALUES
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000005', 1),
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000007', 1),
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000012', 1),
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000018', 1),
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000021', 1),
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000025', 1),
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000031', 1),
  ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000035', 1);

-- ─── Ratings ─────────────────────────────────────────────────────

INSERT INTO ratings (user_id, build_id, score, review_text) VALUES
  ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', 5, 'Excellent build! Great part selection for gaming.'),
  ('a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000001', 4, 'Solid choices. Would suggest a beefier cooler for the 7700X though.'),
  ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002', 5, 'Perfect for content creation workflows!'),
  ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003', 5, 'TechPro delivers quality as always.'),
  ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003', 5, 'Amazing pre-built, incredible value.'),
  ('a0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000003', 4, 'Nice build, would have gone with a bigger case though.');

-- ─── Comments ────────────────────────────────────────────────────

INSERT INTO comments (id, user_id, build_id, parent_comment_id, content) VALUES
  ('f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', NULL, 'What FPS are you getting in AAA titles at 1440p?'),
  ('f0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'Getting 100-140 FPS in most titles at max settings!'),
  ('f0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003', NULL, 'How long does shipping typically take?'),
  ('f0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000003', 'Usually 5-7 business days after order confirmation.');

-- ─── Likes ───────────────────────────────────────────────────────

INSERT INTO likes (user_id, build_id) VALUES
  ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001'),
  ('a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000001'),
  ('a0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000001'),
  ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002'),
  ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003'),
  ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003'),
  ('a0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000003'),
  ('a0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003'),
  ('a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000003');

-- ─── Build Requests ────────────────────────────────────────────────

INSERT INTO build_requests (id, build_id, user_id, budget, purpose, notes, preferred_builder_id, status) VALUES
  ('g0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 1700.00, 'Gaming', 'Looking for someone to build this for me. Need RGB lighting.', 'a0000000-0000-0000-0000-000000000004', 'open'),
  ('g0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 2600.00, 'Content Creation', 'Need this built urgently for video editing work.', NULL, 'open');

-- ─── Showcase Inquiries ────────────────────────────────────────────

INSERT INTO showcase_inquiries (id, user_id, build_id, builder_id, message, status) VALUES
  ('h0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004', 'Is this build still available? Can I get it with 32GB RAM instead?', 'pending'),
  ('h0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004', 'What is the warranty on this build?', 'accepted');

-- ─── Compatibility Rules ─────────────────────────────────────────

INSERT INTO compatibility_rules (rule_number, name, severity, rule_config, message_template) VALUES
  (1, 'CPU-Motherboard Socket Match', 'error',
   '{"type":"field_match","part_a":"cpu","part_b":"motherboard","field_a":"socket","field_b":"socket"}',
   'CPU socket ({a}) does not match motherboard socket ({b})'),

  (2, 'RAM-Motherboard Type Match', 'error',
   '{"type":"field_match","part_a":"ram","part_b":"motherboard","field_a":"type","field_b":"ram_type"}',
   'RAM type ({a}) does not match motherboard RAM type ({b})'),

  (3, 'RAM Modules vs Motherboard Slots', 'error',
   '{"type":"field_lte","part_a":"ram","part_b":"motherboard","field_a":"modules","field_b":"ram_slots"}',
   'RAM modules ({a}) exceeds motherboard RAM slots ({b})'),

  (4, 'RAM Capacity vs Motherboard Max', 'error',
   '{"type":"field_lte","part_a":"ram","part_b":"motherboard","field_a":"total_capacity_gb","field_b":"max_ram_gb"}',
   'RAM capacity ({a}GB) exceeds motherboard max ({b}GB)'),

  (5, 'Motherboard Form Factor vs Case', 'error',
   '{"type":"array_contains","part_a":"motherboard","part_b":"case","field_a":"form_factor","field_b":"supported_motherboards"}',
   'Motherboard form factor ({a}) is not supported by case (supports: {b})'),

  (6, 'GPU Length vs Case Max', 'error',
   '{"type":"field_lte","part_a":"gpu","part_b":"case","field_a":"length_mm","field_b":"max_gpu_length_mm"}',
   'GPU length ({a}mm) exceeds case max GPU length ({b}mm)'),

  (7, 'Cooler Socket Compatibility', 'error',
   '{"type":"array_contains","part_a":"cpu","part_b":"cooling","field_a":"socket","field_b":"socket_compatibility"}',
   'Cooler does not support CPU socket ({a}). Supported: {b}'),

  (8, 'Air Cooler Height vs Case Max', 'error',
   '{"type":"field_lte","part_a":"cooling","part_b":"case","field_a":"height_mm","field_b":"max_cooler_height_mm","condition":{"part":"cooling","field":"type","equals":"Air"}}',
   'Cooler height ({a}mm) exceeds case max cooler height ({b}mm)'),

  (9, 'AIO Radiator vs Case Support', 'error',
   '{"type":"array_contains_formatted","part_a":"cooling","part_b":"case","field_a":"radiator_size_mm","field_b":"radiator_support","format":"{value}mm","condition":{"part":"cooling","field":"type","equals":"AIO"}}',
   'AIO radiator size ({a}) is not supported by case (supports: {b})'),

  (10, 'PSU Wattage vs Total TDP', 'warning',
   '{"type":"sum_gte","target_part":"psu","target_field":"wattage","sum_fields":[{"part":"cpu","field":"tdp_watts"},{"part":"gpu","field":"tdp_watts"}],"multiplier":1.2}',
   'PSU wattage ({a}W) may be insufficient. Recommended: {b}W+ (total TDP x 1.2)'),

  (11, 'PSU-Case Form Factor', 'warning',
   '{"type":"pair_mismatch","part_a":"psu","part_b":"case","field_a":"form_factor","field_b":"form_factor","pairs":[{"a":"ATX","b":"ITX","msg":"ATX PSU may not fit in ITX case. Consider an SFX power supply."},{"a":"SFX","b":"ATX","msg":"SFX PSU in ATX case — make sure you have an SFX-to-ATX bracket."}]}',
   'PSU/Case form factor mismatch'),

  (12, 'M.2 Storage vs Motherboard Slots', 'error',
   '{"type":"field_lte","part_a":"storage","part_b":"motherboard","field_a":"_m2_count","field_b":"m2_slots","condition":{"part":"storage","field":"interface","equals":"M.2"}}',
   'M.2 storage count ({a}) exceeds motherboard M.2 slots ({b})');
