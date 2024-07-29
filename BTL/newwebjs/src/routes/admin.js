const express = require('express');
const router = express.Router();

const AdminController = require('../controllers/adminController');
const adminController = require('../controllers/adminController');


///so-khach-hang-thanh-toan con thieu cau truy van

router.get('/bang-khach-hang', adminController.show);
router.get('/Invoice-taget-Info', adminController.taget);
router.get('/SumtInfo', adminController.sum);
router.use('/', AdminController.index);


module.exports = router;

