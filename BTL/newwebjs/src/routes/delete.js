const express = require('express');
const bodyParser = require('body-parser');
const router = express.Router();

const DeleteController = require('../controllers/deleteController');

router.use(bodyParser.urlencoded({ extended: true }));

router.post('/delete-user', DeleteController.delete);
router.use('/', DeleteController.index);

module.exports = router;