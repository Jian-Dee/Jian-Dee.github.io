const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.post("/", async (req, res) => {
    try {
        const { renter_id, area_id, rent_started, rent_ended } = req.body;

        if (!renter_id || !area_id || !rent_started || !rent_ended) {
            return res.status(400).json({ error: "All fields are required" });
        }

        const sql = "CALL AddRentRecord(?, ?, ?, ?)";
        db.query(sql, [renter_id, area_id, rent_started, rent_ended], (err, results) => {
            if (err) {
                console.error("Database error:", err);
                return res.status(500).json({ error: "Server error: " + err.message });
            }
            res.status(200).json({ message: "Rent record added successfully", results });
        });
    } catch (error) {
        console.error("Server error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;