const express = require("express");
const fs = require("fs");
const path = require("path");
const app = express();

// File logging setup
const logDir = process.env.LOG_DIR || "/tmp";
const logFile = path.join(logDir, "app.log");

// Ensure log directory exists
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

function logToFile(message) {
  const timestamp = new Date().toISOString();
  const logLine = `[${timestamp}] ${message}\n`;

  // Log to stdout (for kubectl logs)
  console.log(logLine.trim());

  // Also write to EBS volume
  fs.appendFile(logFile, logLine, (err) => {
    if (err) console.error("File log error:", err);
  });
}

// Configuration from Environment Variables
const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || "1.0-default";

app.get("/", (req, res) => {
  logToFile("Handling request");

  res.json({
    message: "Hello from EKS",
    version: VERSION,
    timestamp: new Date()
  });
});

// Health check endpoint
app.get("/health", (req, res) => {
  logToFile("Health check");
  res.status(200).send("OK");
});

const server = app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}, version: ${VERSION}`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM signal received: closing HTTP server");
  server.close(() => {
    console.log("HTTP server closed");
  });
});
