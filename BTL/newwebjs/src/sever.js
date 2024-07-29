require('dotenv').config();
const path = require('path');
const express = require('express');
const morgan = require('morgan');
// const handlebars = require('express-handlebars');
const bodyParser = require('body-parser');
const app = express();
const port = 3000;

const ConfigViewEngine = require('./config/viewengine');
const route = require('./routes');
const connectDB = require('./config/db/connectDB');
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());


//Connect Database
connectDB();
//




//HTTP logger
app.use(morgan('combined'));

// config Template engine
ConfigViewEngine(app);

//route init
route(app);

app.listen(port, () => {
    console.log(`Example app listening at http://localhost:${port}`)
});