const quantityCalculator = require('../src/services/quantityCalculator');
const laborCalculator = require('../src/services/laborCalculator');
const productCatalog = require('../src/services/productCatalog');

// Mock dependencies if needed, or simple unit tests
// For now, testing logic correctness assuming DB mocks or pure functions where possible

describe('QuantityCalculator', () => {
  test('should calculate waste correctly', async () => {
    const item = { item_id: 'uuid-123' };
    const measurement = 100;
    const wasteFactor = {
      cut_waste_percentage: 10,
      breakage_percentage: 5,
      pattern_match_percentage: 0
    };

    // Mock getWasteFactors
    quantityCalculator.getWasteFactors = jest.fn().mockResolvedValue(wasteFactor);

    const result = await quantityCalculator.calculateMaterialQuantity(item, measurement, {});
    
    // Base: 100
    // Cut: 10 (10%)
    // Breakage: 5 (5%)
    // Total: 115
    expect(result.base_quantity).toBe(100);
    expect(result.total_quantity).toBe(115);
    expect(result.waste_details.cut_waste).toBe(10);
  });
});

describe('LaborCalculator', () => {
  test('should calculate labor hours with difficulty', async () => {
    const item = { item_id: 'labor-uuid' };
    const quantity = 100;
    const laborTask = {
      base_production_rate: 0.1, // 0.1 hours per unit
      setup_time_hours: 1,
      cleanup_time_hours: 0.5,
      difficulty_multiplier: 1.2
    };

    laborCalculator.getLaborTask = jest.fn().mockResolvedValue(laborTask);
    laborCalculator.getLaborRate = jest.fn().mockResolvedValue(50); // $50/hr

    const result = await laborCalculator.calculateLaborHours(item, quantity, {});

    // Base: 100 * 0.1 = 10 hours
    // With Difficulty: 10 * 1.2 = 12 hours
    // Setup/Cleanup: 1 + 0.5 = 1.5 hours
    // Total: 13.5 hours
    expect(result.base_hours).toBe(10);
    expect(result.total_hours).toBe(13.5);
    expect(result.total_labor_cost).toBe(13.5 * 50);
  });
});
