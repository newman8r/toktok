/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// Test endpoint to verify our function deployment and communication
export const testYoutubeEndpoint = onRequest(async (request, response) => {
  logger.info("YouTube download endpoint test called", {
    timestamp: new Date().toISOString(),
    method: request.method,
    headers: request.headers,
  });

  // Send a test response
  response.json({
    status: "success",
    message: "YouTube download endpoint is ready! 🚀",
    serverTime: new Date().toISOString(),
    receivedMethod: request.method,
  });
});

// Export YouTube functions
export * from "./youtube";
