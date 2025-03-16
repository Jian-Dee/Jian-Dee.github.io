const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.put("/:id", (req, res) => {
    const { name, value } = req.body;
    const { id } = req.params;
    const sql = "UPDATE your_table SET name = ?, value = ? WHERE id = ?";
    db.query(sql, [name, value, id], (err, result) => {
        if (err) return res.status(500).send(err);
        res.send({ message: "Data updated" });
    });
});

module.exports = router;
