const express = require('express');
const router = express.Router();

const sitecontroller = require('../controllers/sitecontroller');

router.use('/gioithieu', sitecontroller.gioithieu);
router.get('/review', sitecontroller.review);

router.get('/banggia', sitecontroller.banggia);

router.use('/', sitecontroller.index);

module.exports = router;