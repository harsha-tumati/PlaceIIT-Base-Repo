const mongoose = require("mongoose");
require("dotenv").config({ path: "./.env" });
const { getShortlistedStudents } = require("./src/controllers/coco.controller");

async function test() {
  await mongoose.connect(process.env.MONGO_URI);
  
  // Just find a company and a student
  const Company = require("./src/models/Company.model");
  const comp = await Company.findOne();
  if(!comp) return console.log("No company");
  
  const req = { params: { companyId: comp._id.toString() }, query: {} };
  const res = {
    status: (code) => ({ json: (data) => console.log("Status", code, JSON.stringify(data, null, 2)) }),
    json: (data) => {
      console.log("JSON Output: ", data.map(d => ({ name: d.name, roll: d.rollNumber, entry: !!d.queueEntry, qId: d.queueEntry ? d.queueEntry._id : null, status: d.queueEntry ? d.queueEntry.status : null })));
    }
  };
  
  await getShortlistedStudents(req, res);
  process.exit(0);
}
test();
