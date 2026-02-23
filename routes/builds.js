import { Router } from 'express';
import pool from '../config/db.js';
import { authenticate, optionalAuth } from '../middleware/auth.js';
import { evaluateRules } from '../utils/compatibility.js';

const router = Router();

const REQUIRED_PARTS = ['cpu', 'motherboard', 'ram', 'psu', 'case'];

function validateMinimumParts(buildParts) {
  if (!buildParts || Object.keys(buildParts).length === 0) {
    return { valid: false, missing: REQUIRED_PARTS };
  }
  const present = Object.keys(buildParts).filter(k => buildParts[k]);
  const missing = REQUIRED_PARTS.filter(c => !present.includes(c));
  return { valid: missing.length === 0, missing };
}


router.get('/', async (req, res, next) => {
  try {
    const { status, build_type, creator_id } = req.query;
    let query = 'SELECT b.*, u.display_name as creator_display_name FROM builds b JOIN users u ON b.creator_id = u.id WHERE 1=1';
    const params = [];

    if (status) {
      params.push(status);
      query += ` AND b.status = $${params.length}`;
    }
    if (build_type) {
      params.push(build_type);
      query += ` AND b.build_type = $${params.length}`;
    }
    if (creator_id) {
      params.push(creator_id);
      query += ` AND b.creator_id = $${params.length}`;
    }

    query += ' ORDER BY b.created_at DESC';
    const { rows } = await pool.query(query, params);
    res.json(rows);
  } catch (err) {
    next(err);
  }
});


router.get('/:id', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT b.*, u.display_name as creator_display_name, u.role as creator_role
       FROM builds b JOIN users u ON b.creator_id = u.id
       WHERE b.id = $1`,
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Build not found' });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});


router.get('/:id/parts', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT bp.*, p.name as part_name, p.brand, p.model, p.specifications, p.price, p.image_url,
              pc.id as category_id, pc.category_name
       FROM build_parts bp
       JOIN parts p ON bp.part_id = p.id
       JOIN part_categories pc ON p.category_id = pc.id
       WHERE bp.build_id = $1
       ORDER BY pc.category_name`,
      [req.params.id]
    );

    
    const result = rows.map(row => ({
      id: row.id,
      build_id: row.build_id,
      part_id: row.part_id,
      quantity: row.quantity,
      part: {
        id: row.part_id,
        name: row.part_name,
        brand: row.brand,
        model: row.model,
        specifications: row.specifications,
        price: row.price,
        image_url: row.image_url,
        category_id: row.category_id,
      },
      category: {
        id: row.category_id,
        name: row.category_name,
        slug: row.category_name.toLowerCase().replace(/\s+/g, '-'),
      },
    }));

    res.json(result);
  } catch (err) {
    next(err);
  }
});


router.post('/', authenticate, async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { title, description, purpose, total_price, status, build_type, availability_status, image_urls, specs_summary, parts: buildParts } = req.body;

    const validation = validateMinimumParts(buildParts);
    if (!validation.valid) {
      return res.status(400).json({ 
        error: 'Build must include all required parts', 
        missing_parts: validation.missing 
      });
    }

    if (buildParts && Object.keys(buildParts).length > 0) {
      const issues = await runCompatibilityCheck(client, buildParts);
      const errors = issues.filter(i => i.severity === 'error');
      if (errors.length > 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Compatibility errors', issues });
      }
    }

    const { rows } = await client.query(
      `INSERT INTO builds (creator_id, title, description, purpose, total_price, status, build_type, availability_status, image_urls, specs_summary)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [req.user.id, title, description || null, purpose || null, total_price || 0, status || 'draft', build_type || 'personal', availability_status || null, image_urls || '{}', specs_summary || null]
    );
    const build = rows[0];

    
    if (buildParts) {
      for (const [, partId] of Object.entries(buildParts)) {
        if (partId) {
          await client.query(
            'INSERT INTO build_parts (build_id, part_id, quantity) VALUES ($1, $2, 1)',
            [build.id, partId]
          );
        }
      }
    }

    await client.query('COMMIT');

    
    let warnings = [];
    if (buildParts && Object.keys(buildParts).length > 0) {
      const allIssues = await runCompatibilityCheck(pool, buildParts);
      warnings = allIssues.filter(i => i.severity === 'warning');
    }

    res.status(201).json({ build, warnings });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});


router.put('/:id', authenticate, async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    
    const { rows: existing } = await client.query('SELECT * FROM builds WHERE id = $1', [req.params.id]);
    if (existing.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Build not found' });
    }
    if (existing[0].creator_id !== req.user.id && req.user.role !== 'admin') {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Not authorized' });
    }

    const { title, description, purpose, total_price, status, build_type, availability_status, image_urls, specs_summary, parts: buildParts } = req.body;

    const validation = validateMinimumParts(buildParts);
    if (!validation.valid) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'Build must include all required parts', 
        missing_parts: validation.missing 
      });
    }

    if (buildParts && Object.keys(buildParts).length > 0) {
      const issues = await runCompatibilityCheck(client, buildParts);
      const errors = issues.filter(i => i.severity === 'error');
      if (errors.length > 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Compatibility errors', issues });
      }
    }

    const { rows } = await client.query(
      `UPDATE builds SET title=$1, description=$2, purpose=$3, total_price=$4, status=$5, build_type=$6, availability_status=$7, image_urls=$8, specs_summary=$9
       WHERE id = $10 RETURNING *`,
      [title, description || null, purpose || null, total_price || 0, status || 'draft', build_type || 'personal', availability_status || null, image_urls || '{}', specs_summary || null, req.params.id]
    );
    const build = rows[0];

    
    if (buildParts) {
      await client.query('DELETE FROM build_parts WHERE build_id = $1', [req.params.id]);
      for (const [, partId] of Object.entries(buildParts)) {
        if (partId) {
          await client.query(
            'INSERT INTO build_parts (build_id, part_id, quantity) VALUES ($1, $2, 1)',
            [build.id, partId]
          );
        }
      }
    }

    await client.query('COMMIT');

    let warnings = [];
    if (buildParts && Object.keys(buildParts).length > 0) {
      const allIssues = await runCompatibilityCheck(pool, buildParts);
      warnings = allIssues.filter(i => i.severity === 'warning');
    }

    res.json({ build, warnings });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});


router.delete('/:id', authenticate, async (req, res, next) => {
  try {
    const { rows } = await pool.query('SELECT creator_id FROM builds WHERE id = $1', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Build not found' });
    if (rows[0].creator_id !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Not authorized' });
    }
    await pool.query('DELETE FROM builds WHERE id = $1', [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});




router.get('/:id/ratings', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT r.*, u.display_name as creator_display_name
       FROM ratings r JOIN users u ON r.user_id = u.id
       WHERE r.build_id = $1 ORDER BY r.created_at DESC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});


router.get('/:id/ratings/mine', authenticate, async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      'SELECT * FROM ratings WHERE user_id = $1 AND build_id = $2',
      [req.user.id, req.params.id]
    );
    res.json(rows[0] || null);
  } catch (err) {
    next(err);
  }
});


router.post('/:id/ratings', authenticate, async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { score, review_text } = req.body;
    const { rows } = await client.query(
      `INSERT INTO ratings (user_id, build_id, score, review_text)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [req.user.id, req.params.id, score, review_text || null]
    );

    
    const { rows: stats } = await client.query(
      'SELECT AVG(score)::DECIMAL(3,2) as avg, COUNT(*)::INTEGER as count FROM ratings WHERE build_id = $1',
      [req.params.id]
    );
    await client.query(
      'UPDATE builds SET rating_avg = $1, rating_count = $2 WHERE id = $3',
      [stats[0].avg, stats[0].count, req.params.id]
    );

    await client.query('COMMIT');
    res.status(201).json(rows[0]);
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      return res.status(409).json({ error: 'You have already rated this build' });
    }
    next(err);
  } finally {
    client.release();
  }
});




router.get('/:id/comments', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT c.*, u.display_name as creator_display_name
       FROM comments c JOIN users u ON c.user_id = u.id
       WHERE c.build_id = $1 ORDER BY c.created_at ASC`,
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});


router.post('/:id/comments', authenticate, async (req, res, next) => {
  try {
    const { content, parent_comment_id } = req.body;
    const { rows } = await pool.query(
      `INSERT INTO comments (user_id, build_id, content, parent_comment_id)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [req.user.id, req.params.id, content, parent_comment_id || null]
    );

    
    const { rows: full } = await pool.query(
      `SELECT c.*, u.display_name as creator_display_name
       FROM comments c JOIN users u ON c.user_id = u.id WHERE c.id = $1`,
      [rows[0].id]
    );
    res.status(201).json(full[0]);
  } catch (err) {
    next(err);
  }
});




router.get('/:id/likes', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      'SELECT * FROM likes WHERE build_id = $1',
      [req.params.id]
    );
    res.json(rows);
  } catch (err) {
    next(err);
  }
});


router.get('/:id/likes/check', authenticate, async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      'SELECT id FROM likes WHERE user_id = $1 AND build_id = $2',
      [req.user.id, req.params.id]
    );
    res.json({ liked: rows.length > 0 });
  } catch (err) {
    next(err);
  }
});


router.post('/:id/likes/toggle', authenticate, async (req, res, next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: existing } = await client.query(
      'SELECT id FROM likes WHERE user_id = $1 AND build_id = $2',
      [req.user.id, req.params.id]
    );

    let liked;
    if (existing.length > 0) {
      await client.query('DELETE FROM likes WHERE id = $1', [existing[0].id]);
      await client.query(
        'UPDATE builds SET like_count = GREATEST(0, like_count - 1) WHERE id = $1',
        [req.params.id]
      );
      liked = false;
    } else {
      await client.query(
        'INSERT INTO likes (user_id, build_id) VALUES ($1, $2)',
        [req.user.id, req.params.id]
      );
      await client.query(
        'UPDATE builds SET like_count = like_count + 1 WHERE id = $1',
        [req.params.id]
      );
      liked = true;
    }

    
    const { rows: build } = await client.query(
      'SELECT like_count FROM builds WHERE id = $1',
      [req.params.id]
    );

    await client.query('COMMIT');
    res.json({ liked, like_count: build[0].like_count });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});



async function runCompatibilityCheck(dbClient, partsMap) {
  
  const partIds = Object.values(partsMap).filter(Boolean);
  if (partIds.length === 0) return [];

  
  const { rows: partRows } = await dbClient.query(
    `SELECT p.*, LOWER(REPLACE(pc.category_name, ' ', '-')) as category_slug
     FROM parts p JOIN part_categories pc ON p.category_id = pc.id
     WHERE p.id = ANY($1)`,
    [partIds]
  );

  const selectedParts = {};
  for (const [slug, partId] of Object.entries(partsMap)) {
    const part = partRows.find(p => p.id === partId);
    if (part) selectedParts[slug] = part;
  }

  
  const { rows: rules } = await dbClient.query(
    'SELECT * FROM compatibility_rules WHERE is_active = true ORDER BY rule_number'
  );

  return evaluateRules(rules, selectedParts);
}

export default router;
