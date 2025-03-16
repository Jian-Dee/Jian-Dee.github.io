const mysql = require("mysql");

const connection = mysql.createConnection({
    host: "localhost",
    user: "root",
    password: "",
    database: "your_database"
});

connection.connect(err => {
    if (err) {
        console.error("Database connection failed:", err);
        process.exit(1); // Exit the process on connection failure
    }
    console.log("Database connected!");
});

module.exports = connection;
