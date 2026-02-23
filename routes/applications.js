import { Router } from 'express';
import pool from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.js';

const router = Router();


router.get('/', authenticate, requireRole('admin'), async (req, res, next) => {
  try {
    const { status, user_id } = req.query;
    let query = `SELECT ba.*, u.display_name as user_display_name, u.email as user_email
                 FROM builder_applications ba
                 JOIN users u ON ba.user_id = u.id
                 WHERE 1=1`;
    const params = [];

    if (status) {
      params.push(status);
      query += ` AND ba.status = $${params.length}`;
    }
    if (user_id) {
      params.push(user_id);
      query += ` AND ba.user_id = $${params.length}`;
    }

    query += ' ORDER BY ba.created_at DESC';
    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
});


router.get('/mine', authenticate, async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT ba.*, u.display_name as user_display_name, u.email as user_email
       FROM builder_applications ba
       JOIN users u ON ba.user_id = u.id
       WHERE ba.user_id = $1
       ORDER BY ba.created_at DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});


router.post('/', authenticate, async (req, res, next) => {
  try {
    const { business_name, registration_number, address, website, portfolio_url, years_of_experience, specialization, application_type } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO builder_applications (user_id, business_name, registration_number, address, website, portfolio_url, years_of_experience, specialization, application_type)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [req.user.id, business_name, registration_number || null, address || null, website || null, portfolio_url || null, years_of_experience || null, specialization || null, application_type]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
});


router.put('/:id/review', authenticate, requireRole('admin'), async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { status, admin_notes } = req.body;
    if (!['approved', 'rejected'].includes(status)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Status must be approved or rejected' });
    }

    
    const { rows } = await client.query(
      `UPDATE builder_applications SET status=$1, admin_notes=$2, reviewed_by=$3
       WHERE id = $4 RETURNING *`,
      [status, admin_notes || null, req.user.id, req.params.id]
    );
    if (rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Application not found' });
    }
    const app = rows[0];

    if (status === 'approved') {
      
      await client.query("UPDATE users SET role = 'builder' WHERE id = $1", [app.user_id]);

      
      await client.query(
        `INSERT INTO builder_profiles (user_id, business_name, registration_number, address, website, portfolio_url, years_of_experience, specialization)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (user_id) DO NOTHING`,
        [app.user_id, app.business_name, app.registration_number, app.address, app.website, app.portfolio_url, app.years_of_experience, app.specialization]
      );
    }

    await client.query('COMMIT');
    res.json(app);
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

export default router;
