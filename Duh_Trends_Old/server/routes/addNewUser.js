const express = require("express");
const router = express.Router();
const db = require("../config/db");

router.post("/", async (req, res) => {
    try {
        const { name, username, password, role_name, gender_title, contact_number } = req.body;

        if (!name || !username || !password || !role_name || !gender_title || !contact_number) {
            return res.status(400).json({ error: "All fields are required" });
        }

        const sql = "CALL AddNewUser(?, ?, ?, ?, ?, ?)";
        db.query(sql, [name, username, password, role_name, gender_title, contact_number], (err, results) => {
            if (err) {
                console.error("Database error:", err);
                return res.status(500).json({ error: "Server error: " + err.message });
            }
            res.status(200).json({ message: "User added successfully", results });
        });
    } catch (error) {
        console.error("Server error:", error);
        res.status(500).json({ error: "Internal server error" });
    }
});

module.exports = router;