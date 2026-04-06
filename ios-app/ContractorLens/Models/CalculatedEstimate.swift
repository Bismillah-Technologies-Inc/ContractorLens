import Foundation

struct CalculatedEstimate: Codable {
    let estimateId: String
    let calculationId: String
    let calculatedAt: Date
    let totalAmount: Double
    let breakdown: CalculationBreakdown
    let components: [CalculationComponent]
    
    enum CodingKeys: String, CodingKey {
        case estimateId = "estimate_id"
        case calculationId = "calculation_id"
        case calculatedAt = "calculated_at"
        case totalAmount = "total_amount"
        case breakdown = "breakdown"
        case components = "components"
    }
    
    init(
        estimateId: String,
        calculationId: String,
        calculatedAt: Date,
        totalAmount: Double,
        breakdown: CalculationBreakdown,
        components: [CalculationComponent]
    ) {
        self.estimateId = estimateId
        self.calculationId = calculationId
        self.calculatedAt = calculatedAt
        self.totalAmount = totalAmount
        self.breakdown = breakdown
        self.components = components
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        estimateId = try container.decode(String.self, forKey: .estimateId)
        calculationId = try container.decode(String.self, forKey: .calculationId)
        
        // Parse date
        let calculatedAtString = try container.decode(String.self, forKey: .calculatedAt)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        calculatedAt = dateFormatter.date(from: calculatedAtString) ?? Date()
        
        totalAmount = try container.decode(Double.self, forKey: .totalAmount)
        breakdown = try container.decode(CalculationBreakdown.self, forKey: .breakdown)
        components = try container.decode([CalculationComponent].self, forKey: .components)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(estimateId, forKey: .estimateId)
        try container.encode(calculationId, forKey: .calculationId)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(dateFormatter.string(from: calculatedAt), forKey: .calculatedAt)
        
        try container.encode(totalAmount, forKey: .totalAmount)
        try container.encode(breakdown, forKey: .breakdown)
        try container.encode(components, forKey: .components)
    }
}

struct CalculationBreakdown: Codable {
    let materialCost: Double
    let laborCost: Double
    let equipmentCost: Double
    let subcontractorCost: Double
    let markup: Double
    let tax: Double
    let profitMargin: Double
    let overhead: Double
    
    enum CodingKeys: String, CodingKey {
        case materialCost = "material_cost"
        case laborCost = "labor_cost"
        case equipmentCost = "equipment_cost"
        case subcontractorCost = "subcontractor_cost"
        case markup = "markup"
        case tax = "tax"
        case profitMargin = "profit_margin"
        case overhead = "overhead"
    }
    
    init(
        materialCost: Double,
        laborCost: Double,
        equipmentCost: Double,
        subcontractorCost: Double,
        markup: Double,
        tax: Double,
        profitMargin: Double,
        overhead: Double
    ) {
        self.materialCost = materialCost
        self.laborCost = laborCost
        self.equipmentCost = equipmentCost
        self.subcontractorCost = subcontractorCost
        self.markup = markup
        self.tax = tax
        self.profitMargin = profitMargin
        self.overhead = overhead
    }
}

struct CalculationComponent: Codable, Identifiable {
    let id: String
    let type: String  // "material", "labor", "equipment", "subcontractor"
    let category: String
    let description: String
    let quantity: Double
    let unit: String
    let unitCost: Double
    let totalCost: Double
    let calculationDetails: CalculationDetails?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case type = "type"
        case category = "category"
        case description = "description"
        case quantity = "quantity"
        case unit = "unit"
        case unitCost = "unit_cost"
        case totalCost = "total_cost"
        case calculationDetails = "calculation_details"
    }
}

struct CalculationDetails: Codable {
    let assemblyId: String?
    let csiDivision: String?
    let materialSpecs: MaterialSpecs?
    let laborDetails: LaborCalculationDetails?
    let equipmentDetails: EquipmentDetails?
    
    enum CodingKeys: String, CodingKey {
        case assemblyId = "assembly_id"
        case csiDivision = "csi_division"
        case materialSpecs = "material_specs"
        case laborDetails = "labor_details"
        case equipmentDetails = "equipment_details"
    }
}

struct MaterialSpecs: Codable {
    let brand: String?
    let model: String?
    let color: String?
    let finish: String?
    let size: String?
    let grade: String?
    let manufacturer: String?
    
    init(
        brand: String? = nil,
        model: String? = nil,
        color: String? = nil,
        finish: String? = nil,
        size: String? = nil,
        grade: String? = nil,
        manufacturer: String? = nil
    ) {
        self.brand = brand
        self.model = model
        self.color = color
        self.finish = finish
        self.size = size
        self.grade = grade
        self.manufacturer = manufacturer
    }
}

struct LaborCalculationDetails: Codable {
    let hoursPerUnit: Double
    let crewSize: Int
    let skillLevel: String
    let laborRate: Double
    let overtimeFactor: Double?
    
    enum CodingKeys: String, CodingKey {
        case hoursPerUnit = "hours_per_unit"
        case crewSize = "crew_size"
        case skillLevel = "skill_level"
        case laborRate = "labor_rate"
        case overtimeFactor = "overtime_factor"
    }
    
    init(
        hoursPerUnit: Double,
        crewSize: Int,
        skillLevel: String,
        laborRate: Double,
        overtimeFactor: Double? = nil
    ) {
        self.hoursPerUnit = hoursPerUnit
        self.crewSize = crewSize
        self.skillLevel = skillLevel
        self.laborRate = laborRate
        self.overtimeFactor = overtimeFactor
    }
}

struct EquipmentDetails: Codable {
    let equipmentType: String
    let rentalRate: Double
    let usageHours: Double
    let fuelCost: Double?
    let operatorCost: Double?
    
    enum CodingKeys: String, CodingKey {
        case equipmentType = "equipment_type"
        case rentalRate = "rental_rate"
        case usageHours = "usage_hours"
        case fuelCost = "fuel_cost"
        case operatorCost = "operator_cost"
    }
    
    init(
        equipmentType: String,
        rentalRate: Double,
        usageHours: Double,
        fuelCost: Double? = nil,
        operatorCost: Double? = nil
    ) {
        self.equipmentType = equipmentType
        self.rentalRate = rentalRate
        self.usageHours = usageHours
        self.fuelCost = fuelCost
        self.operatorCost = operatorCost
    }
}