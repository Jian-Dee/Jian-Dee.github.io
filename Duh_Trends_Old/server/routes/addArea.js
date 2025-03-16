const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.post("/", async (req, res) => {
    const { area_name, type_name, size, price, description } = req.body;

    if (!area_name || !type_name || !size || !price || !description) {
        return res.status(400).json({ error: "All fields are required" });
    }

    try {
        const sql = "CALL AddArea(?, ?, ?, ?, ?)";
        const values = [area_name, type_name, size, price, description];

        db.query(sql, values, (err, results) => {
            if (err) {
                console.error("Database error:", err);
                return res.status(500).json({ error: "Database Error" });
            }
            res.status(200).json({ message: "Area added successfully", results });
        });
    } catch (error) {
        console.error("Server error:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

module.exports = router;