import { Router } from 'express';
import pool from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.js';
import { evaluateRules } from '../utils/compatibility.js';

const router = Router();


router.post('/check', async (req, res, next) => {
  try {
    const { parts: partsMap } = req.body;
    if (!partsMap || typeof partsMap !== 'object') {
      return res.status(400).json({ error: 'parts object required' });
    }

    const partIds = Object.values(partsMap).filter(Boolean);
    if (partIds.length === 0) {
      return res.json({ issues: [] });
    }

    
    const { rows: partRows } = await pool.query(
      `SELECT p.*, pc.category_name
       FROM parts p JOIN part_categories pc ON p.category_id = pc.id
       WHERE p.id = ANY($1)`,
      [partIds]
    );

    
    const selectedParts = {};
    for (const [slug, partId] of Object.entries(partsMap)) {
      const part = partRows.find(p => p.id === partId);
      if (part) {
        part.category_slug = part.category_name.toLowerCase();
        selectedParts[slug] = part;
      }
    }

    
    const { rows: rules } = await pool.query(
      'SELECT * FROM compatibility_rules WHERE is_active = true ORDER BY rule_number'
    );
    console.log("Checked")
    const issues = evaluateRules(rules, selectedParts);
    console.log(issues)
    res.json({ issues });
  } catch (err) {
    next(err);
  }
});


router.get('/rules', authenticate, requireRole('admin'), async (_req, res, next) => {
  try {
    const { rows } = await pool.query('SELECT * FROM compatibility_rules ORDER BY rule_number');
    res.json(rows);
  } catch (err) {
    next(err);
  }
});


router.post('/rules', authenticate, requireRole('admin'), async (req, res, next) => {
  try {
    const { rule_number, name, description, severity, rule_config, message_template, is_active } = req.body;

    if (!rule_number || !name || !severity || !rule_config || !message_template) {
      return res.status(400).json({ error: 'rule_number, name, severity, rule_config, and message_template are required' });
    }

    if (!['error', 'warning'].includes(severity)) {
      return res.status(400).json({ error: 'severity must be "error" or "warning"' });
    }

    const { rows } = await pool.query(
      `INSERT INTO compatibility_rules (rule_number, name, description, severity, rule_config, message_template, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [rule_number, name, description || null, severity, JSON.stringify(rule_config), message_template, is_active !== false]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(400).json({ error: 'Rule number already exists' });
    }
    next(err);
  }
});


router.put('/rules/:id', authenticate, requireRole('admin'), async (req, res, next) => {
  try {
    const { is_active, severity, rule_config, message_template } = req.body;
    const fields = [];
    const values = [];
    let idx = 1;

    if (is_active !== undefined) { fields.push(`is_active = $${idx++}`); values.push(is_active); }
    if (severity !== undefined) { fields.push(`severity = $${idx++}`); values.push(severity); }
    if (rule_config !== undefined) { fields.push(`rule_config = $${idx++}`); values.push(JSON.stringify(rule_config)); }
    if (message_template !== undefined) { fields.push(`message_template = $${idx++}`); values.push(message_template); }

    if (fields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(req.params.id);
    const { rows } = await pool.query(
      `UPDATE compatibility_rules SET ${fields.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Rule not found' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});


router.delete('/rules/:id', authenticate, requireRole('admin'), async (req, res, next) => {
  try {
    const { rowCount } = await pool.query('DELETE FROM compatibility_rules WHERE id = $1', [req.params.id]);
    if (rowCount === 0) return res.status(404).json({ error: 'Rule not found' });
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

export default router;
