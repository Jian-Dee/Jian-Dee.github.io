const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.post("/", async (req, res) => {
    try {
        const { renter_id, item_id, quantity, item_price, item_description } = req.body;

        if (!renter_id || !item_id || !quantity || !item_price || !item_description) {
            return res.status(400).json({ error: "All fields are required" });
        }

        const sql = "CALL AddItemToStock(?, ?, ?, ?, ?)";
        db.query(sql, [renter_id, item_id, quantity, item_price, item_description], (err, results) => {
            if (err) {
                console.error("Database error:", err);
                return res.status(500).json({ error: "Server error: " + err.message });
            }
            res.status(200).json({ message: "Item added to stock successfully", results });
        });
    } catch (error) {
        console.error("Server error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;