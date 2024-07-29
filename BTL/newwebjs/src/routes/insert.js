const express = require('express');
const bodyParser = require('body-parser');
const router = express.Router();

const InsertController = require('../controllers/InsertController');


router.use(bodyParser.urlencoded({ extended: true }));

router.post('/insert-user', InsertController.add);
router.use('/', InsertController.index);

module.exports = router;