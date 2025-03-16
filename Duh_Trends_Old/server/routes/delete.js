const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.delete("/:id", (req, res) => {
    const { id } = req.params;
    const sql = "DELETE FROM your_table WHERE id = ?";
    db.query(sql, [id], (err, result) => {
        if (err) return res.status(500).send(err);
        res.send({ message: "Data deleted" });
    });
});

module.exports = router;
