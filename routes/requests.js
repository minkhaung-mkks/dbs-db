import { Router } from 'express';
import pool from '../config/db.js';
import { authenticate } from '../middleware/auth.js';

const router = Router();


router.get('/', async (req, res, next) => {
  try {
    const { status, user_id, build_id } = req.query;
    let query = `SELECT br.*, u.display_name as user_display_name,
                        b.title as build_title, b.total_price as build_total_price,
                        b.image_urls as build_image_urls,
                        pb.display_name as preferred_builder_name
                 FROM build_requests br
                 JOIN users u ON br.user_id = u.id
                 JOIN builds b ON br.build_id = b.id
                 LEFT JOIN users pb ON br.preferred_builder_id = pb.id
                 WHERE 1=1`;
    const params = [];

    if (status) {
      params.push(status);
      query += ` AND br.status = $${params.length}`;
    }
    if (user_id) {
      params.push(user_id);
      query += ` AND br.user_id = $${params.length}`;
    }
    if (build_id) {
      params.push(build_id);
      query += ` AND br.build_id = $${params.length}`;
    }

    query += ' ORDER BY br.created_at DESC';
    const { rows } = await pool.query(query, params);
    
    const result = rows.map(row => ({
      ...row,
      build_image_urls: row.build_image_urls || [],
    }));
    
    res.json(result);
  } catch (err) {
    next(err);
  }
});


router.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT br.*, u.display_name as user_display_name, u.email as user_email,
              b.title as build_title, b.total_price as build_total_price, b.description as build_description,
              b.image_urls as build_image_urls,
              pb.display_name as preferred_builder_name
       FROM build_requests br
       JOIN users u ON br.user_id = u.id
       JOIN builds b ON br.build_id = b.id
       LEFT JOIN users pb ON br.preferred_builder_id = pb.id
       WHERE br.id = $1`,
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Request not found' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});


router.post('/', authenticate, async (req, res, next) => {
  try {
    const { build_id, budget, purpose, notes, preferred_builder_id } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO build_requests (build_id, user_id, budget, purpose, notes, preferred_builder_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [build_id, req.user.id, budget || null, purpose || null, notes || null, preferred_builder_id || null]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
});


router.put('/:id', authenticate, async (req, res, next) => {
  try {
    const { rows: existing } = await pool.query('SELECT * FROM build_requests WHERE id = $1', [req.params.id]);
    if (existing.length === 0) return res.status(404).json({ error: 'Request not found' });
    if (existing[0].user_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }

    const { budget, purpose, notes, status, preferred_builder_id } = req.body;
    const { rows } = await pool.query(
      `UPDATE build_requests SET budget=$1, purpose=$2, notes=$3, status=$4, preferred_builder_id=$5
       WHERE id = $6 RETURNING *`,
      [budget || null, purpose || null, notes || null, status || existing[0].status, preferred_builder_id || null, req.params.id]
    );
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});

export default router;
