const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.get("/", (req, res) => {
    db.query("SELECT * FROM your_table", (err, results) => {
        if (err) return res.status(500).send(err);
        res.send(results);
    });
});

module.exports = router;
