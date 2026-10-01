const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {setGlobalOptions} = require("firebase-functions/v2");
const {HttpsError, onCall} = require("firebase-functions/v2/https");

const {
  PERSONALIZED_STORY_ID,
  createSampleStoryForUser,
} = require("./story");

initializeApp();
setGlobalOptions({maxInstances: 10});

exports.createSampleStory = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must be signed in to create a story.",
    );
  }

  try {
    await createSampleStoryForUser({
      firestore: getFirestore(),
      userId: request.auth.uid,
    });
  } catch (error) {
    if (error?.code === "profile-not-ready") {
      throw new HttpsError(
          "failed-precondition",
          "Complete onboarding before creating a story.",
      );
    }
    throw error;
  }

  return {storyId: PERSONALIZED_STORY_ID};
});
