const pool = require('../config/database');

/**
 * User model for contractorlens.Users table operations
 */
class UserModel {
  /**
   * Find or create user by Firebase UID
   * @param {Object} userData - User data from Firebase
   * @param {Object} profileData - Additional profile data
   * @returns {Promise<Object>} User record
   */
  static async findOrCreateUser(firebaseUid, email, profileData = {}) {
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Check if user already exists
      const checkQuery = `
        SELECT user_id, firebase_uid, email, display_name, company_name, 
               default_quality_tier, created_at
        FROM contractorlens.Users 
        WHERE firebase_uid = $1
      `;
      
      const checkResult = await client.query(checkQuery, [firebaseUid]);
      
      if (checkResult.rows.length > 0) {
        // User exists, update if needed
        const user = checkResult.rows[0];
        
        // Update if email or profile data changed
        if (email !== user.email || profileData.displayName !== user.display_name || 
            profileData.companyName !== user.company_name) {
          const updateQuery = `
            UPDATE contractorlens.Users 
            SET email = $1, display_name = $2, company_name = $3
            WHERE user_id = $4
            RETURNING user_id, firebase_uid, email, display_name, company_name, 
                      default_quality_tier, created_at
          `;
          
          const updateResult = await client.query(updateQuery, [
            email,
            profileData.displayName || user.display_name,
            profileData.companyName || user.company_name,
            user.user_id
          ]);
          
          await client.query('COMMIT');
          return updateResult.rows[0];
        }
        
        await client.query('COMMIT');
        return user;
      }

      // Create new user
      const createQuery = `
        INSERT INTO contractorlens.Users 
        (firebase_uid, email, display_name, company_name, default_quality_tier)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING user_id, firebase_uid, email, display_name, company_name, 
                  default_quality_tier, created_at
      `;
      
      const createResult = await client.query(createQuery, [
        firebaseUid,
        email,
        profileData.displayName || null,
        profileData.companyName || null,
        'better' // Default quality tier
      ]);
      
      await client.query('COMMIT');
      return createResult.rows[0];
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Get user by Firebase UID
   * @param {string} firebaseUid - Firebase UID
   * @returns {Promise<Object|null>} User record or null
   */
  static async getUserByFirebaseUid(firebaseUid) {
    const query = `
      SELECT user_id, firebase_uid, email, display_name, company_name, 
             default_quality_tier, created_at
      FROM contractorlens.Users 
      WHERE firebase_uid = $1
    `;
    
    const result = await pool.query(query, [firebaseUid]);
    return result.rows.length > 0 ? result.rows[0] : null;
  }

  /**
   * Get user by ID
   * @param {string} userId - User UUID
   * @returns {Promise<Object|null>} User record or null
   */
  static async getUserById(userId) {
    const query = `
      SELECT user_id, firebase_uid, email, display_name, company_name, 
             default_quality_tier, created_at
      FROM contractorlens.Users 
      WHERE user_id = $1
    `;
    
    const result = await pool.query(query, [userId]);
    return result.rows.length > 0 ? result.rows[0] : null;
  }

  /**
   * Update user profile
   * @param {string} userId - User UUID
   * @param {Object} updates - Profile updates
   * @returns {Promise<Object>} Updated user record
   */
  static async updateUserProfile(userId, updates) {
    const { displayName, companyName, defaultQualityTier } = updates;
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (displayName !== undefined) {
      fields.push(`display_name = $${paramIndex}`);
      values.push(displayName);
      paramIndex++;
    }

    if (companyName !== undefined) {
      fields.push(`company_name = $${paramIndex}`);
      values.push(companyName);
      paramIndex++;
    }

    if (defaultQualityTier !== undefined) {
      fields.push(`default_quality_tier = $${paramIndex}`);
      values.push(defaultQualityTier);
      paramIndex++;
    }

    if (fields.length === 0) {
      return this.getUserById(userId);
    }

    values.push(userId);
    
    const query = `
      UPDATE contractorlens.Users 
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE user_id = $${paramIndex}
      RETURNING user_id, firebase_uid, email, display_name, company_name, 
                default_quality_tier, created_at
    `;
    
    const result = await pool.query(query, values);
    return result.rows[0];
  }
}

module.exports = UserModel;