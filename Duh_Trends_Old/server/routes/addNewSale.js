const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.post("/", async (req, res) => {
    try {
        const { staff_id, item_id, quantity, renter_id } = req.body;

        if (!staff_id || !item_id || !quantity || !renter_id) {
            return res.status(400).json({ error: "All fields are required" });
        }

        const sql = "CALL AddNewSale(?, ?, ?, ?)";
        db.query(sql, [staff_id, item_id, quantity, renter_id], (err, results) => {
            if (err) {
                console.error("Database error:", err);
                return res.status(500).json({ error: "Server error: " + err.message });
            }
            res.status(200).json({ message: "Sale recorded successfully", results });
        });
    } catch (error) {
        console.error("Server error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;