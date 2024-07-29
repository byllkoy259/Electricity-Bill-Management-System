const InsertRouter = require('./insert');
const TracuuRouter = require('./tracuu');
const siteRouter = require('./site');
const deleteRouter = require('./delete');
const AdminRouter = require('./admin');


function route(app) {

    app.get('/tracuu', TracuuRouter);
    app.get('/search-invoice', TracuuRouter);
    app.get('/search-consumption', TracuuRouter);
    app.get('/searchCustomerInvoice', TracuuRouter);

    app.get('/insert', InsertRouter);
    app.post('/insert-user', InsertRouter);


    app.post('/delete-user', deleteRouter);
    app.get('/delete', deleteRouter);


    app.get('/tra-cuu-admin', AdminRouter);
    app.get('/Invoice-taget-Info', AdminRouter);
    app.get('/bang-khach-hang', AdminRouter);
    app.get('/SumtInfo', AdminRouter);


    app.get('/gioithieu', siteRouter);
    app.get('/review', siteRouter);
    app.get('/banggia', siteRouter);
    app.get('/', siteRouter);

}

module.exports = route;
