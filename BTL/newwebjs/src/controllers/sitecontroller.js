const sequelize = require('../config/db/sequelize');

//lucs suawr laij sau
class SiteController {

    // [GET] /home
    index(req, res) {
        res.render('Home');
    }
    review(req, res) {
        res.render('review');
    }

    // [GET] / gioithieu
    gioithieu(req, res) {
        res.render('Gioithieu');
    }

    async banggia(req, res) {
        try {
            const [results, metadata] = await sequelize.query('SELECT * FROM Price');
            // console.log('>>> results...', results);
            return res.render('banggia', { customers: results });
        } catch (error) {
            console.error('Error:', error);
            res.send(`Error: ${error.message}`);
        }
    }
}

module.exports = new SiteController;