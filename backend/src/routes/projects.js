const express = require('express');
const router = express.Router();

// Stub for projects router
router.get('/', (req, res) => {
  res.json({ projects: [], pagination: { page: 1, limit: 20, total: 0 } });
});

module.exports = router;
