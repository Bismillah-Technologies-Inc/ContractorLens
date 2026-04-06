const express = require('express');
const Joi = require('joi');
const { authenticate } = require('../middleware/auth');
const AssemblyEngine = require('../services/assemblyEngine');
const db = require('../config/database');
const { firestore } = require('../config/firebase');

const router = express.Router();
const assemblyEngine = require('../services/assemblyEngine');

// Input validation schemas
const takeoffDataSchema = Joi.object({
  walls: Joi.array().items(Joi.object({
    area: Joi.number().positive().required(),
    height: Joi.number().positive().optional(),
    type: Joi.string().optional()
  })).optional(),
  floors: Joi.array().items(Joi.object({
    area: Joi.number().positive().required(),
    type: Joi.string().optional()
  })).optional(),
  ceilings: Joi.array().items(Joi.object({
    area: Joi.number().positive().required(),
    type: Joi.string().optional()
  })).optional(),
  kitchens: Joi.array().items(Joi.object({
    area: Joi.number().positive().required(),
    type: Joi.string().optional()
  })).optional(),
  bathrooms: Joi.array().items(Joi.object({
    area: Joi.number().positive().required(),
    type: Joi.string().optional()
  })).optional()
});

const estimateRequestSchema = Joi.object({
  takeoffData: takeoffDataSchema.required(),
  jobType: Joi.string().valid('kitchen', 'bathroom', 'room', 'exterior', 'flooring', 'wall', 'ceiling').required(),
  finishLevel: Joi.string().valid('good', 'better', 'best').required(),
  zipCode: Joi.string().pattern(/^\d{5}(-\d{4})?$/).required(),
  projectId: Joi.string().uuid().optional(),
  notes: Joi.string().max(1000).optional()
});

/**
 * GET /api/v1/estimates
 * Retrieve user's estimates with pagination and filtering
 */
router.get('/api/v1/estimates', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 10, status, projectId } = req.query;
    const offset = (page - 1) * limit;
    
    let whereClause = 'WHERE user_id = $1';
    const queryParams = [req.user.uid];
    let paramIndex = 2;
    
    if (status) {
      whereClause += ` AND status = $${paramIndex}`;
      queryParams.push(status);
      paramIndex++;
    }
    
    if (projectId) {
      whereClause += ` AND project_id = $${paramIndex}`;
      queryParams.push(projectId);
      paramIndex++;
    }
    
    // Get estimates with basic info (not full line items for performance)
    const result = await db.query(`
      SELECT estimate_id, project_id, job_type, finish_level, 
             status, grand_total, location_data,
             created_at, updated_at
      FROM contractorlens.estimates 
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `, [...queryParams, limit, offset]);
    
    // Get total count for pagination
    const countResult = await db.query(`
      SELECT COUNT(*) as total 
      FROM contractorlens.estimates 
      ${whereClause}
    `, queryParams);
    
    const total = parseInt(countResult.rows[0].total);
    const totalPages = Math.ceil(total / limit);
    
    res.json({
      estimates: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1
      }
    });
    
  } catch (error) {
    console.error('Error retrieving estimates:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve estimates',
      code: 'RETRIEVAL_FAILED'
    });
  }
});

/**
 * POST /api/v1/estimates
 * Create a new estimate using Assembly Engine
 */
router.post('/api/v1/estimates', authenticate, async (req, res) => {
  try {
    // Validate request body
    const { error, value } = estimateRequestSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ 
        error: 'Invalid request data',
        details: error.details,
        code: 'VALIDATION_FAILED'
      });
    }
    
    const { takeoffData, jobType, finishLevel, zipCode, projectId, notes } = value;
    
    console.log(`Creating estimate for user ${req.user.uid}: ${jobType} job, ${finishLevel} finish level`);
    
    // Get user settings from Firestore
    let userSettings;
    try {
      const userDoc = await firestore.collection('userSettings').doc(req.user.uid).get();
      
      if (userDoc.exists) {
        userSettings = userDoc.data();
      } else {
        // Default settings if user hasn't configured them
        userSettings = {
          hourly_rate: 50,
          markup_percentage: 25,
          tax_rate: 0.08,
          preferred_quality_tier: finishLevel
        };
        
        // Save default settings for future use
        await firestore.collection('userSettings').doc(req.user.uid).set(userSettings);
      }
    } catch (firestoreError) {
      console.error('Firestore error, using defaults:', firestoreError);
      userSettings = {
        hourly_rate: 50,
        markup_percentage: 25,
        tax_rate: 0.08
      };
    }
    
    // Calculate estimate using Assembly Engine
    const estimate = await assemblyEngine.calculateEstimate(
      takeoffData,
      jobType,
      finishLevel,
      zipCode,
      userSettings
    );
    
    // Save estimate to database
    const estimateId = await saveEstimate({
      userId: req.user.uid,
      projectId: projectId || null,
      jobType,
      finishLevel,
      zipCode,
      takeoffData,
      estimate,
      notes,
      status: 'draft'
    });
    
    // Response includes the full estimate
    res.status(201).json({
      estimateId,
      status: 'draft',
      createdAt: new Date().toISOString(),
      ...estimate
    });
    
  } catch (error) {
    console.error('Estimate calculation error:', error);
    
    if (error.message.includes('Invalid')) {
      return res.status(400).json({ 
        error: error.message,
        code: 'CALCULATION_FAILED'
      });
    }
    
    res.status(500).json({ 
      error: 'Failed to calculate estimate',
      code: 'INTERNAL_ERROR'
    });
  }
});

/**
 * GET /api/v1/estimates/:id
 * Retrieve a specific estimate with full details
 */
router.get('/api/v1/estimates/:id', authenticate, async (req, res) => {
  try {
    const estimateId = req.params.id;
    
    // Validate UUID format
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(estimateId)) {
      return res.status(400).json({ 
        error: 'Invalid estimate ID format',
        code: 'INVALID_ID'
      });
    }
    
    const result = await db.query(`
      SELECT estimate_id, user_id, project_id, job_type, finish_level,
             status, takeoff_data, estimate_data, location_data, notes,
             created_at, updated_at
      FROM contractorlens.estimates
      WHERE estimate_id = $1 AND user_id = $2
    `, [estimateId, req.user.uid]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        error: 'Estimate not found',
        code: 'NOT_FOUND'
      });
    }
    
    const estimate = result.rows[0];
    
    res.json({
      estimateId: estimate.estimate_id,
      projectId: estimate.project_id,
      jobType: estimate.job_type,
      finishLevel: estimate.finish_level,
      status: estimate.status,
      takeoffData: estimate.takeoff_data,
      locationData: estimate.location_data,
      notes: estimate.notes,
      createdAt: estimate.created_at,
      updatedAt: estimate.updated_at,
      ...estimate.estimate_data // Spread the calculated estimate data
    });
    
  } catch (error) {
    console.error('Error retrieving estimate:', error);
    res.status(500).json({ 
      error: 'Failed to retrieve estimate',
      code: 'RETRIEVAL_FAILED'
    });
  }
});

/**
 * PUT /api/v1/estimates/:id/status
 * Update estimate status (draft -> approved -> invoiced)
 */
router.put('/api/v1/estimates/:id/status', authenticate, async (req, res) => {
  try {
    const estimateId = req.params.id;
    const { status } = req.body;
    
    const validStatuses = ['draft', 'approved', 'invoiced', 'archived'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ 
        error: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
        code: 'INVALID_STATUS'
      });
    }
    
    const result = await db.query(`
      UPDATE contractorlens.estimates
      SET status = $1, updated_at = NOW()
      WHERE estimate_id = $2 AND user_id = $3
      RETURNING estimate_id, status, updated_at
    `, [status, estimateId, req.user.uid]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        error: 'Estimate not found',
        code: 'NOT_FOUND'
      });
    }
    
    res.json({
      estimateId: result.rows[0].estimate_id,
      status: result.rows[0].status,
      updatedAt: result.rows[0].updated_at
    });
    
  } catch (error) {
    console.error('Error updating estimate status:', error);
    res.status(500).json({ 
      error: 'Failed to update estimate status',
      code: 'UPDATE_FAILED'
    });
  }
});

/**
 * DELETE /api/v1/estimates/:id
 * Delete an estimate (only if in draft status)
 */
router.delete('/api/v1/estimates/:id', authenticate, async (req, res) => {
  try {
    const estimateId = req.params.id;
    
    const result = await db.query(`
      DELETE FROM contractorlens.estimates
      WHERE estimate_id = $1 AND user_id = $2 AND status = 'draft'
      RETURNING estimate_id
    `, [estimateId, req.user.uid]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        error: 'Estimate not found or cannot be deleted (only draft estimates can be deleted)',
        code: 'CANNOT_DELETE'
      });
    }
    
    res.json({
      message: 'Estimate deleted successfully',
      estimateId: result.rows[0].estimate_id
    });
    
  } catch (error) {
    console.error('Error deleting estimate:', error);
    res.status(500).json({ 
      error: 'Failed to delete estimate',
      code: 'DELETE_FAILED'
    });
  }
});

/**
 * Helper function to save estimate to database
 */
async function saveEstimate(data) {
  const {
    userId, projectId, jobType, finishLevel, zipCode,
    takeoffData, estimate, notes, status
  } = data;
  
  // First check if estimates table exists, if not create it
  await ensureEstimatesTable();
  
  const result = await db.query(`
    INSERT INTO contractorlens.estimates (
      user_id, project_id, job_type, finish_level,
      takeoff_data, estimate_data, location_data, notes, status,
      grand_total
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    RETURNING estimate_id
  `, [
    userId,
    projectId,
    jobType,
    finishLevel,
    JSON.stringify(takeoffData),
    JSON.stringify(estimate),
    JSON.stringify(estimate.metadata?.location),
    notes,
    status,
    estimate.grandTotal
  ]);
  
  return result.rows[0].estimate_id;
}

/**
 * Ensure estimates table exists (create if needed)
 */
async function ensureEstimatesTable() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS contractorlens.estimates (
      estimate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id VARCHAR(255) NOT NULL,
      project_id UUID REFERENCES contractorlens.Projects(project_id) ON DELETE SET NULL,
      
      -- Estimate parameters
      job_type VARCHAR(50) NOT NULL,
      finish_level VARCHAR(20) NOT NULL CHECK (finish_level IN ('good', 'better', 'best')),
      
      -- Data storage
      takeoff_data JSONB NOT NULL,
      estimate_data JSONB NOT NULL,
      location_data JSONB,
      notes TEXT,
      
      -- Quick access fields for queries
      grand_total DECIMAL(10,2),
      
      -- Status tracking
      status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'invoiced', 'archived')),
      
      -- Metadata
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW()
    )
  `);
  
  // Create indexes if they don't exist
  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_estimates_user_id ON contractorlens.estimates(user_id);
    CREATE INDEX IF NOT EXISTS idx_estimates_project_id ON contractorlens.estimates(project_id);
    CREATE INDEX IF NOT EXISTS idx_estimates_status ON contractorlens.estimates(status);
    CREATE INDEX IF NOT EXISTS idx_estimates_created_at ON contractorlens.estimates(created_at);
  `);
}

module.exports = router;