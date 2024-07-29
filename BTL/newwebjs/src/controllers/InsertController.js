const sequelize = require('../config/db/sequelize');

class InsertController {

    // [GET] /login
    index(req, res) {
        res.render('insert');
    }


    async add(req, res) {
        try {
            // Lấy dữ liệu từ req.body
            const { email, customer_id, first_name, last_name, address, city, phone, identity_number, service_id } = req.body;

            // Thực hiện insert vào cơ sở dữ liệu
            const result = await sequelize.query(`
                INSERT INTO customer (email, customer_id, first_name, last_name, address, city, phone, identity_number, service_id) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                { replacements: [email, customer_id, first_name, last_name, address, city, phone, identity_number, service_id] }
            );

            // Kiểm tra kết quả insert và hiển thị thông báo
            if (result) {
                console.log('Inserted successfully:', result);
                res.send('Customer inserted successfully!');
            } else {
                console.error('Insert failed');
                res.send('Failed to insert customer');
            }
        } catch (error) {
            console.error('Error:', error);
            res.send(`Error: ${error.message}`);
        }
    }

}

module.exports = new InsertController;