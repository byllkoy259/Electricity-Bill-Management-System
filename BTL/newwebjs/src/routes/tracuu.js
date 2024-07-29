const express = require('express');
const router = express.Router();

const TracuuController = require('../controllers/tracuuControler');

router.get('/tracuu', TracuuController.index);
router.get('/search-invoice', TracuuController.searchInvoice);
router.get('/search-consumption', TracuuController.searchConsumption);
router.get('/searchCustomerInvoice', TracuuController.searchCustomerInvoices);

module.exports = router;