const sequelize = require('../config/db/sequelize');

class AdminController {
    index(req, res) {

        res.render('admin');
    }

    async show(req, res) {
        try {
            const [results, metadata] = await sequelize.query('SELECT customer_id, first_name, last_name, address, city, phone, email, identity_number, service_id FROM customer');
            // console.log('>>> results...', results);
            return res.render('table', { customers: results });
        } catch (error) {
            console.error('Error:', error);
            res.send(`Error: ${error.message}`);
        }
    }
    async taget(req, res) {
        try {
            const [results, metadata] = await sequelize.query('SELECT * FROM Invoice ORDER BY consumption ASC');
            console.log('>>> results...', results);
            return res.render('Invoice-taget-Info', { taget: results });
        } catch (error) {
            console.error('Error:', error);
            res.send(`Error: ${error.message}`);
        }
    }
    async sum(req, res) {
        try {
            // Truy vấn để tính tổng lượng tiêu thụ điện theo từng dịch vụ
            const [consumptionResults, consumptionMetadata] = await sequelize.query(`
                SELECT 
                    s.name AS service_name, 
                    SUM(i.consumption) AS total_consumption 
                FROM 
                    Invoice i
                INNER JOIN 
                    Service s ON i.service_id = s.service_id 
                GROUP BY 
                    s.name
            `);

            // Truy vấn để đếm số lượng khách hàng theo từng dịch vụ
            const [customerCountResults, customerCountMetadata] = await sequelize.query(`
                SELECT 
                    s.name AS service_name,
                    COUNT(c.customer_id) AS customer_count
                FROM 
                    Service s
                JOIN 
                    Customer c ON s.service_id = c.service_id
                GROUP BY 
                    s.name
                ORDER BY 
                    customer_count DESC
            `);

            // In kết quả vào console để kiểm tra
            console.log('>>> consumptionResults...', consumptionResults);
            console.log('>>> customerCountResults...', customerCountResults);

            // Render template với dữ liệu tổng hợp
            return res.render('SumtInfo', { consumptionResults, customerCountResults });
        } catch (error) {
            // In lỗi ra console và trả về lỗi cho client
            console.error('Error:', error);
            res.send(`Error: ${error.message}`);
        }
    }


}

module.exports = new AdminController();


