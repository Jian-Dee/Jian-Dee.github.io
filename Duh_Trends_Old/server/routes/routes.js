const express = require("express");
const router = express.Router();

const insert = require("./insert");
const get = require("./get");
const update = require("./update");
const remove = require("./delete");

const addArea = require("./addArea");
const addItem = require("./addItem");
const addItemToStock = require("./addItemToStock");
const addNewSale = require("./addNewSale");
const addNewUser = require("./addNewUser");
const addPaymentHistoryRecord = require("./addPaymentHistoryRecord");
const addRentRecord = require("./addRentRecord");





router.use("/insert", insert);
router.use("/get", get);
router.use("/update", update);
router.use("/delete", remove);

router.use("/addArea", addArea);
router.use("/addItem", addItem);
router.use("/addItemToStock", addItemToStock);
router.use("/addNewSale", addNewSale);
router.use("/addNewUser", addNewUser);
router.use("/addPaymentHistoryRecord", addPaymentHistoryRecord);
router.use("/addRentRecord", addRentRecord);

module.exports = router;
