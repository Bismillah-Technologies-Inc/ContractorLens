const db = require('../config/database');
const { firestore } = require('../config/firebase');

/**
 * Project Model - Database operations for Projects
 */
class ProjectModel {
  /**
   * Create a new project
   * @param {Object} projectData - Project data including name, description, address, status, clientId, createdBy
   * @param {string} userId - Firebase UID of authenticated user
   * @returns {Promise<string>} - New project ID
   */
  static async create(projectData, userId) {
    try {
      const {
        name,
        description,
        address,
        clientId,
        status = 'active'
      } = projectData;

      // First, verify the client belongs to the user
      const clientResult = await db.query(
        `SELECT client_id FROM contractorlens.Clients WHERE client_id = $1 AND user_id = $2`,
        [clientId, userId]
      );

      if (clientResult.rows.length === 0) {
        throw new Error('Client not found or does not belong to user');
      }

      // Insert project
      const result = await db.query(
        `INSERT INTO contractorlens.Projects (
          client_id, created_by, name, description, address, status
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING project_id`,
        [clientId, userId, name, description, JSON.stringify(address), status]
      );

      return result.rows[0].project_id;
    } catch (error) {
      console.error('ProjectModel.create error:', error);
      throw error;
    }
  }

  /**
   * Get all projects for a user with pagination
   * @param {string} userId - Firebase UID
   * @param {number} page - Page number (1-indexed)
   * @param {number} limit - Items per page
   * @param {string} status - Filter by status (optional)
   * @returns {Promise<Object>} - Projects and pagination info
   */
  static async getAll(userId, page = 1, limit = 10, status = null) {
    try {
      const offset = (page - 1) * limit;
      
      let whereClause = 'WHERE p.created_by = $1';
      const queryParams = [userId];
      let paramIndex = 2;
      
      if (status) {
        whereClause += ` AND p.status = $${paramIndex}`;
        queryParams.push(status);
        paramIndex++;
      }

      // Get projects with client info and estimate count
      const result = await db.query(`
        SELECT 
          p.project_id,
          p.name,
          p.description,
          p.address,
          p.status,
          p.created_at,
          p.updated_at,
          c.client_id,
          c.first_name || ' ' || c.last_name as client_name,
          c.email as client_email,
          (SELECT COUNT(*) FROM contractorlens.Estimates e WHERE e.project_id = p.project_id) as estimate_count
        FROM contractorlens.Projects p
        LEFT JOIN contractorlens.Clients c ON p.client_id = c.client_id
        ${whereClause}
        ORDER BY p.updated_at DESC
        LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
      `, [...queryParams, limit, offset]);

      // Get total count
      const countResult = await db.query(`
        SELECT COUNT(*) as total
        FROM contractorlens.Projects p
        ${whereClause}
      `, queryParams);

      const total = parseInt(countResult.rows[0].total);
      const totalPages = Math.ceil(total / limit);

      return {
        projects: result.rows.map(row => ({
          ...row,
          address: typeof row.address === 'string' ? JSON.parse(row.address) : row.address
        })),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      };
    } catch (error) {
      console.error('ProjectModel.getAll error:', error);
      throw error;
    }
  }

  /**
   * Get a specific project by ID
   * @param {string} projectId - Project UUID
   * @param {string} userId - Firebase UID for authorization
   * @returns {Promise<Object>} - Project details
   */
  static async getById(projectId, userId) {
    try {
      const result = await db.query(`
        SELECT 
          p.project_id,
          p.name,
          p.description,
          p.address,
          p.status,
          p.created_at,
          p.updated_at,
          p.client_id,
          c.first_name || ' ' || c.last_name as client_name,
          c.email as client_email,
          c.phone as client_phone,
          c.address as client_address,
          (SELECT COUNT(*) FROM contractorlens.Estimates e WHERE e.project_id = p.project_id) as estimate_count,
          (SELECT JSON_AGG(JSON_BUILD_OBJECT(
            'estimate_id', estimate_id,
            'job_type', job_type,
            'status', status,
            'grand_total', grand_total,
            'created_at', created_at
          )) FROM contractorlens.Estimates e WHERE e.project_id = p.project_id AND e.status != 'archived') as estimates
        FROM contractorlens.Projects p
        LEFT JOIN contractorlens.Clients c ON p.client_id = c.client_id
        WHERE p.project_id = $1 AND p.created_by = $2
      `, [projectId, userId]);

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows[0];
      
      return {
        ...row,
        address: typeof row.address === 'string' ? JSON.parse(row.address) : row.address,
        client_address: typeof row.client_address === 'string' ? JSON.parse(row.client_address) : row.client_address,
        estimates: row.estimates || []
      };
    } catch (error) {
      console.error('ProjectModel.getById error:', error);
      throw error;
    }
  }

  /**
   * Update a project
   * @param {string} projectId - Project UUID
   * @param {Object} updateData - Fields to update
   * @param {string} userId - Firebase UID for authorization
   * @returns {Promise<boolean>} - Success status
   */
  static async update(projectId, updateData, userId) {
    try {
      const validFields = ['name', 'description', 'address', 'status', 'client_id'];
      const updateFields = [];
      const values = [];
      let paramIndex = 1;

      // Build dynamic update query
      for (const [key, value] of Object.entries(updateData)) {
        if (validFields.includes(key)) {
          updateFields.push(`${key} = $${paramIndex}`);
          values.push(key === 'address' ? JSON.stringify(value) : value);
          paramIndex++;
        }
      }

      if (updateFields.length === 0) {
        return false; // Nothing to update
      }

      // Add updated_at timestamp
      updateFields.push('updated_at = NOW()');
      
      // Add WHERE clause parameters
      values.push(projectId, userId);
      
      const query = `
        UPDATE contractorlens.Projects
        SET ${updateFields.join(', ')}
        WHERE project_id = $${paramIndex} AND created_by = $${paramIndex + 1}
        RETURNING project_id
      `;

      const result = await db.query(query, values);

      return result.rows.length > 0;
    } catch (error) {
      console.error('ProjectModel.update error:', error);
      throw error;
    }
  }

  /**
   * Soft delete (archive) a project
   * @param {string} projectId - Project UUID
   * @param {string} userId - Firebase UID for authorization
   * @returns {Promise<boolean>} - Success status
   */
  static async archive(projectId, userId) {
    try {
      const result = await db.query(`
        UPDATE contractorlens.Projects
        SET status = 'archived', updated_at = NOW()
        WHERE project_id = $1 AND created_by = $2 AND status != 'archived'
        RETURNING project_id
      `, [projectId, userId]);

      return result.rows.length > 0;
    } catch (error) {
      console.error('ProjectModel.archive error:', error);
      throw error;
    }
  }

  /**
   * Check if user owns the client
   * @param {string} clientId - Client UUID
   * @param {string} userId - Firebase UID
   * @returns {Promise<boolean>} - Ownership status
   */
  static async userOwnsClient(clientId, userId) {
    try {
      const result = await db.query(
        `SELECT client_id FROM contractorlens.Clients WHERE client_id = $1 AND user_id = $2`,
        [clientId, userId]
      );
      return result.rows.length > 0;
    } catch (error) {
      console.error('ProjectModel.userOwnsClient error:', error);
      throw error;
    }
  }
}

module.exports = ProjectModel;