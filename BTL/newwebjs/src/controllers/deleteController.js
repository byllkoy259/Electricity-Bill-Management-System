const sequelize = require('../config/db/sequelize');

class DeleteController {

    index(req, res) {
        res.render('Delete');
    }

    async delete(req, res) {
        const { customerId, identityNumber } = req.body; // Sửa tên trường để phù hợp với form HTML

        // Kiểm tra xem customerId và identityNumber có tồn tại không
        if (!customerId || !identityNumber) {
            return res.status(400).send('Không tìm thấy thông tin khách hàng');
        }

        try {
            // Thực hiện truy vấn xóa khách hàng
            const result = await sequelize.query(
                'DELETE FROM customer WHERE customer_id = :customerId AND identity_number = :identityNumber',
                {
                    replacements: { customerId, identityNumber }, // Sửa thành customerId và identityNumber
                    type: sequelize.QueryTypes.DELETE
                }
            );

            res.send('Customer deleted successfully');
        } catch (error) {
            console.error('Error:', error);
            res.status(500).send(`Error: ${error.message}`);
        }
    }

}

module.exports = new DeleteController;