const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.post("/", (req, res) => {
    const { name, value } = req.body;
    const sql = "INSERT INTO your_table (name, value) VALUES (?, ?)";
    db.query(sql, [name, value], (err, result) => {
        if (err) return res.status(500).send(err);
        res.send({ message: "Data inserted", id: result.insertId });
    });
});

module.exports = router;
