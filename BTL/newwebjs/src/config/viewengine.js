const path = require('path');
const handlebars = require('express-handlebars');
const express = require('express');
const morgan = require('morgan');


const ConfigViewEngine = (app) => {
    app.engine('hbs', handlebars.engine({
        extname: '.hbs'
    }));
    app.set('view engine', 'hbs');
    app.set('views', path.join('./src', 'resources', 'views')); //Nếu cho cònig engine ra ssever thif thay đổi './src' thành __dirname

    //config static fille
    app.use(express.static(path.join('./src', 'public')));

}

module.exports = ConfigViewEngine;