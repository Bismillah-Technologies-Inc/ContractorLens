-- Patch to fix missing items and link Level 5 data correctly

-- 1. Add missing Drywall items (needed for LaborTasks example)
INSERT INTO ContractorLens.Items (csi_code, description, unit, category, subcategory, quantity_per_unit, quality_tier, item_type, national_average_cost) 
SELECT '09 29 00', 'Drywall Installation', 'SF', 'drywall', 'wall', 0.016, 'good', 'labor', 1.50
WHERE NOT EXISTS (SELECT 1 FROM ContractorLens.Items WHERE csi_code = '09 29 00' AND item_type = 'labor');

INSERT INTO ContractorLens.Items (csi_code, description, unit, category, subcategory, quantity_per_unit, quality_tier, item_type, national_average_cost)
SELECT '09 29 00', 'Drywall Sheet Material', 'SF', 'drywall', 'wall', 1.05, 'good', 'material', 0.60
WHERE NOT EXISTS (SELECT 1 FROM ContractorLens.Items WHERE csi_code = '09 29 00' AND item_type = 'material');

-- Update Trade IDs for new items
UPDATE ContractorLens.Items i SET trade_id = t.trade_id FROM ContractorLens.Trades t WHERE substring(i.csi_code from 1 for 2) = t.csi_division AND i.trade_id IS NULL;


-- 2. Retry LaborTasks inserts with correct codes
-- Drywall (Now exists)
INSERT INTO ContractorLens.LaborTasks (item_id, task_name, base_production_rate, crew_size, skill_level, setup_time_hours, cleanup_time_hours)
SELECT item_id, 'Install 1/2" Gypsum Board', 0.016, 2, 'journeyman', 0.5, 1.0
FROM ContractorLens.Items WHERE csi_code = '09 29 00' AND item_type = 'labor'
ON CONFLICT DO NOTHING;

-- Paint (Use 09 91 20 Premium Paint Application instead of 09 91 23)
INSERT INTO ContractorLens.LaborTasks (item_id, task_name, base_production_rate, crew_size, skill_level, setup_time_hours, cleanup_time_hours)
SELECT item_id, 'Apply Two Coats of Latex Paint', 0.016, 1, 'journeyman', 1.0, 0.75
FROM ContractorLens.Items WHERE csi_code = '09 91 20' AND item_type = 'labor'
ON CONFLICT DO NOTHING;


-- 3. Retry MaterialSpecifications with correct codes
-- Drywall (Now exists)
INSERT INTO ContractorLens.MaterialSpecifications (item_id, manufacturer, model_number, brand_name, size_dimensions, weight)
SELECT item_id, 'USG', '222834', 'Sheetrock', '4 ft. x 8 ft. x 1/2 in.', 54.4
FROM ContractorLens.Items WHERE csi_code = '09 29 00' AND item_type = 'material'
ON CONFLICT DO NOTHING;

-- Paint (Use 09 91 21 Premium Interior Paint)
INSERT INTO ContractorLens.MaterialSpecifications (item_id, manufacturer, model_number, brand_name, color_finish)
SELECT item_id, 'Sherwin-Williams', 'SW-7006', 'ProClassic', 'Pure White'
FROM ContractorLens.Items WHERE csi_code = '09 91 21' AND item_type = 'material'
ON CONFLICT DO NOTHING;

-- Tile (Use 09 30 14 Ceramic Tile Material - Better Grade, instead of 09 30 13 which is labor)
INSERT INTO ContractorLens.MaterialSpecifications (item_id, manufacturer, model_number, brand_name, size_dimensions, color_finish)
SELECT item_id, 'Daltile', 'X70112121P', 'Color Wheel Classic', '12 in. x 12 in.', 'White'
FROM ContractorLens.Items WHERE csi_code = '09 30 14' AND item_type = 'material'
ON CONFLICT DO NOTHING;
