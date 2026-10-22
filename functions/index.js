const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {setGlobalOptions} = require("firebase-functions/v2");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const {
  createPersonalizedStoryForUser,
  ensureSharedThemeStories,
} = require("./story");

initializeApp();
setGlobalOptions({maxInstances: 10});
const openaiApiKey = defineSecret("OPENAI_API_KEY");

exports.createPersonalizedStory = onCall({
  secrets: [openaiApiKey],
  timeoutSeconds: 300,
}, async (request) => {
  logger.info("Story generation request received", {
    authenticated: Boolean(request.auth),
    appCheckPresent: Boolean(request.app),
  });

  if (!request.auth) {
    logger.warn("Story generation rejected: unauthenticated");
    throw new HttpsError(
        "unauthenticated",
        "You must be signed in to create a story.",
    );
  }

  try {
    const storyId = await createPersonalizedStoryForUser({
      firestore: getFirestore(),
      storageBucket: getStorage().bucket(),
      userId: request.auth.uid,
    });
    logger.info("Story generation request completed", {storyId});
    return {storyId};
  } catch (error) {
    logger.error("Story generation request failed", {
      name: error?.name,
      code: error?.code,
      status: error?.status,
      type: error?.type,
      message: error?.message,
      requestId: error?.request_id,
      stack: error?.stack,
      causeName: error?.cause?.name,
      causeCode: error?.cause?.code,
      causeStatus: error?.cause?.status,
      causeType: error?.cause?.type,
      causeMessage: error?.cause?.message,
      causeRequestId: error?.cause?.request_id,
    });
    if (error?.code === "profile-not-ready") {
      throw new HttpsError(
          "failed-precondition",
          "Complete onboarding before creating a story.",
      );
    }
    if (error?.code === "generation-failed") {
      throw new HttpsError(
          "internal",
          "The story could not be generated. Please try again.",
      );
    }
    throw error;
  }
});

exports.ensureSharedThemeStories = onCall({
  secrets: [openaiApiKey],
  timeoutSeconds: 540,
}, async (request) => {
  if (!request.auth && process.env.FUNCTIONS_EMULATOR !== "true") {
    throw new HttpsError(
        "unauthenticated",
        "You must be signed in to load shared stories.",
    );
  }

  try {
    const results = await ensureSharedThemeStories({
      firestore: getFirestore(),
      storageBucket: getStorage().bucket(),
    });
    logger.info("Shared theme stories are ready", {results});
    return {results};
  } catch (error) {
    logger.error("Shared theme story generation failed", {
      code: error?.code,
      message: error?.message,
      stack: error?.stack,
    });
    throw new HttpsError(
        "internal",
        "The shared stories could not be prepared. Please try again.",
    );
  }
});
