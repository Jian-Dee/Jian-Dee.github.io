// server.js
const express = require("express");
const bodyParser = require("body-parser");
const db = require("./config/db");
const routes = require("./routes/routes");

const app = express();
app.use(bodyParser.json());
app.use("/api", routes);

const PORT = 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
