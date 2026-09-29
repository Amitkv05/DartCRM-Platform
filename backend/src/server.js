import dotenv from "dotenv";
import { db } from "./config/db.js";
import { app } from "./app.js";

dotenv.config();

const port = Number(process.env.PORT || 5000);

async function start() {
  await db.query("SELECT 1");
  app.listen(port, "0.0.0.0", () => {
    console.log(`CRM backend running on http://localhost:${port}`);
    console.log(`Physical devices can use http://<YOUR-PC-IP>:${port}`);
  });
}

start().catch((error) => {
  console.error("Failed to start CRM backend:", error);
  process.exit(1);
});
