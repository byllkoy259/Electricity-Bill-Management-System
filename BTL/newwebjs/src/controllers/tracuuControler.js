const sequelize = require('../config/db/sequelize');
class TracuuController {

    // [GET] /tracuu
    index(req, res) {
        res.render('Tracuu');
    }
    async searchInvoice(req, res) {
        try {
            const { identity_number } = req.query;

            // Truy vấn thông tin từ bảng Customer và kết hợp với Invoice
            const results = await sequelize.query(`
                SELECT 
                    c.first_name, c.last_name, c.customer_id, c.identity_number,
                    i.*
                FROM 
                    Customer c
                JOIN 
                    Invoice i ON c.customer_id = i.customer_id
                WHERE 
                    c.identity_number = :identityNumber
            `, {
                replacements: { identityNumber: identity_number },
                type: sequelize.QueryTypes.SELECT
            });

            // Truy vấn thông tin từ bảng Payment
            const payments = await sequelize.query(`
                SELECT * FROM Payment WHERE invoice_id IN 
                (SELECT invoice_id FROM Invoice WHERE customer_id IN 
                (SELECT customer_id FROM Customer WHERE identity_number = :identityNumber))
            `, {
                replacements: { identityNumber: identity_number },
                type: sequelize.QueryTypes.SELECT
            });

            res.render('search-result', { results, payments, queryOption: 'invoice' });
        } catch (error) {
            console.error('Error:', error);
            res.status(500).send(`Error: ${error.message}`);
        }
    }
    ///
    async searchConsumption(req, res) {
        try {
            const { identity_number } = req.query;

            // Truy vấn thông tin từ bảng MeterReading của khách hàng
            const meterReadings = await sequelize.query(
                `SELECT 
                    MR.reading_id,
                    MR.reading_date,
                    MR.old_index,
                    MR.new_index,
                    MR.multiplier,
                    MR.consumption
                FROM 
                    Customer AS C
                JOIN 
                    Meter AS M ON C.customer_id = M.customer_id
                JOIN 
                    MeterReading AS MR ON M.meter_id = MR.meter_id
                WHERE 
                    C.identity_number = :identityNumber`,
                {
                    replacements: { identityNumber: identity_number },
                    type: sequelize.QueryTypes.SELECT
                }
            );
            const price = await sequelize.query(
                `SELECT 
                    P.price_id,
                    P.start_date,
                    P.tier_1,
                    P.tier_2,
                    P.tier_3,
                    P.tier_4,
                    P.tier_5,
                    P.tier_6
                FROM 
                    Customer AS C
                JOIN 
                    Meter AS M ON C.customer_id = M.customer_id
                JOIN 
                    MeterReading AS MR ON M.meter_id = MR.meter_id
                JOIN 
                    Price AS P ON MR.service_id = P.service_id
                WHERE 
                    C.identity_number = :identityNumber`,
                {
                    replacements: { identityNumber: identity_number },
                    type: sequelize.QueryTypes.SELECT
                }
            );



            // Render template và truyền dữ liệu vào
            res.render('search-consumption', { meterReadings, price, queryOption: 'consumption' });
        } catch (error) {
            console.error('Error:', error);
            res.status(500).send(`Error: ${error.message}`);
        }
    }
    //





    /////////////////////////////////////////////////////////////////////////////////
    async searchCustomerInvoices(req, res) {
        try {
            const { identity_number } = req.query;

            if (!identity_number) {
                return res.status(400).send("Missing identity number");
            }

            // Truy vấn thông tin từ bảng Customer
            const customerData = await sequelize.query(`
                SELECT 
                    c.first_name, c.last_name, c.customer_id, c.identity_number
                FROM 
                    Customer c
                WHERE 
                    c.identity_number = :identityNumber
            `, {
                replacements: { identityNumber: identity_number },
                type: sequelize.QueryTypes.SELECT
            });

            // Kiểm tra nếu không tìm thấy khách hàng
            if (customerData.length === 0) {
                return res.status(404).send("Customer not found");
            }

            const customer = customerData[0];

            // Truy vấn thông tin hóa đơn của khách hàng
            const invoices = await sequelize.query(`
                SELECT 
                    i.invoice_id, 
                    i.invoice_date, 
                    i.consumption, 
                    i.vat
                FROM 
                    Invoice i
                JOIN 
                    Customer c ON i.customer_id = c.customer_id
                WHERE 
                    c.identity_number = :identityNumber
            `, {
                replacements: { identityNumber: identity_number },
                type: sequelize.QueryTypes.SELECT
            });
            const payments = await sequelize.query(`
                SELECT * FROM Payment WHERE invoice_id IN 
                (SELECT invoice_id FROM Invoice WHERE customer_id IN 
                (SELECT customer_id FROM Customer WHERE identity_number = :identityNumber))
            `, {
                replacements: { identityNumber: identity_number },
                type: sequelize.QueryTypes.SELECT
            });
            const price = await sequelize.query(
                `SELECT 
                    P.price_id,
                    P.start_date,
                    P.tier_1,
                    P.tier_2,
                    P.tier_3,
                    P.tier_4,
                    P.tier_5,
                    P.tier_6
                FROM 
                    Customer AS C
                JOIN 
                    Meter AS M ON C.customer_id = M.customer_id
                JOIN 
                    MeterReading AS MR ON M.meter_id = MR.meter_id
                JOIN 
                    Price AS P ON MR.service_id = P.service_id
                WHERE 
                    C.identity_number = :identityNumber`,
                {
                    replacements: { identityNumber: identity_number },
                    type: sequelize.QueryTypes.SELECT
                }
            );




            // Render template và truyền dữ liệu vào
            res.render('searchCustomerInvoice', { customer, invoices, payments, price });
        } catch (error) {
            // Log lỗi ra console
            console.error('Error:', error);
            res.status(500).send(`Error: ${error.message}`);
        }
    }


}

module.exports = new TracuuController;