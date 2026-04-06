const express = require('express');
const Joi = require('joi');
const db = require('../config/database');

const router = express.Router();

// Validation schemas
const registerSchema = Joi.object({
  displayName: Joi.string().max(100).optional().allow(''),
  companyName: Joi.string().max(200).optional().allow('')
});

const updateProfileSchema = Joi.object({
  displayName: Joi.string().max(100).optional().allow(''),
  companyName: Joi.string().max(200).optional().allow(''),
  defaultQualityTier: Joi.string().valid('good', 'better', 'best').optional()
});

// POST /api/v1/auth/register
// Creates or updates user profile in contractorlens.Users table
router.post('/register', async (req, res) => {
  try {
    const { error, value } = registerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message, code: 'VALIDATION_FAILED' });
    }

    const { uid, email } = req.user;
    const { displayName, companyName } = value;

    const query = `
      INSERT INTO contractorlens.Users (user_id, email, display_name, company_name)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (user_id) DO UPDATE 
      SET 
        email = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, contractorlens.Users.display_name),
        company_name = COALESCE(EXCLUDED.company_name, contractorlens.Users.company_name)
      RETURNING user_id AS "userId", email, display_name AS "displayName", company_name AS "companyName", default_quality_tier AS "defaultQualityTier", created_at AS "createdAt"
    `;

    const { rows } = await db.query(query, [uid, email, displayName || null, companyName || null]);

    res.status(201).json({ user: rows[0] });
  } catch (err) {
    console.error('Error in /api/v1/auth/register:', err);
    res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
});

// GET /api/v1/auth/profile
// Returns user profile + finish preferences
router.get('/profile', async (req, res) => {
  try {
    const { uid } = req.user;

    const query = `
      SELECT 
        user_id AS "userId", 
        email, 
        display_name AS "displayName", 
        company_name AS "companyName", 
        default_quality_tier AS "defaultQualityTier", 
        created_at AS "createdAt"
      FROM contractorlens.Users
      WHERE user_id = $1
    `;

    const { rows } = await db.query(query, [uid]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User profile not found', code: 'NOT_FOUND' });
    }

    res.json({ user: rows[0] });
  } catch (err) {
    console.error('Error in /api/v1/auth/profile GET:', err);
    res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
});

// PUT /api/v1/auth/profile
// Updates displayName, companyName, defaultQualityTier
router.put('/profile', async (req, res) => {
  try {
    const { error, value } = updateProfileSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message, code: 'VALIDATION_FAILED' });
    }

    const { uid } = req.user;
    const { displayName, companyName, defaultQualityTier } = value;

    // Build the update query dynamically based on what was provided
    let updateFields = [];
    let values = [uid];
    let valueIdx = 2;

    if (displayName !== undefined) {
      updateFields.push(`display_name = $${valueIdx++}`);
      values.push(displayName);
    }
    if (companyName !== undefined) {
      updateFields.push(`company_name = $${valueIdx++}`);
      values.push(companyName);
    }
    if (defaultQualityTier !== undefined) {
      updateFields.push(`default_quality_tier = $${valueIdx++}`);
      values.push(defaultQualityTier);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields provided for update', code: 'VALIDATION_FAILED' });
    }

    const query = `
      UPDATE contractorlens.Users
      SET ${updateFields.join(', ')}
      WHERE user_id = $1
      RETURNING user_id AS "userId", email, display_name AS "displayName", company_name AS "companyName", default_quality_tier AS "defaultQualityTier", created_at AS "createdAt"
    `;

    const { rows } = await db.query(query, values);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User profile not found', code: 'NOT_FOUND' });
    }

    res.json({ user: rows[0] });
  } catch (err) {
    console.error('Error in /api/v1/auth/profile PUT:', err);
    res.status(500).json({ error: 'Internal server error', code: 'INTERNAL_ERROR' });
  }
});

module.exports = router;
