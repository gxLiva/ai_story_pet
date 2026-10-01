const {FieldValue} = require("firebase-admin/firestore");

const PERSONALIZED_STORY_ID = "personalized";

function buildSampleStory() {
  return {
    id: PERSONALIZED_STORY_ID,
    title: "The Moonlight Garden",
    category: "Curiosity",
    coverImagePath: "assets/images/lumi_fox.png",
    pages: [
      {
        id: "moonlight-page-1",
        imagePath: "assets/images/lumi_fox.png",
        text: "Lumi found a silver seed glowing beside the garden path.",
      },
      {
        id: "moonlight-page-2",
        imagePath: "assets/images/lumi_fox.png",
        text: "Lumi planted it gently and wondered what it might become.",
      },
      {
        id: "moonlight-page-3",
        imagePath: "assets/images/lumi_fox.png",
        text: "A tiny leaf appeared, and Lumi felt curious.",
        feelingCheck: {
          id: "moonlight-curious-check",
          title: "What does curious feel like?",
          focusPhrase: "curious",
          quote: "“Lumi felt curious.”",
          questions: [
            {
              id: "moonlight-feeling",
              prompt: "Pick a feeling",
              correctOptionId: "curious",
              options: [
                {id: "curious", label: "Curious", emoji: "🤔"},
                {id: "angry", label: "Angry", emoji: "😠"},
                {id: "sleepy", label: "Sleepy", emoji: "😴"},
              ],
            },
            {
              id: "moonlight-evidence",
              prompt: "How do you know?",
              correctOptionId: "wondered",
              options: [
                {
                  id: "wondered",
                  label: "Lumi wondered what would grow",
                  emoji: "🌱",
                },
                {
                  id: "walked-away",
                  label: "Lumi walked away",
                  emoji: "🚶",
                },
              ],
            },
          ],
        },
      },
      {
        id: "moonlight-page-4",
        imagePath: "assets/images/lumi_fox.png",
        text: "Lumi watered the sprout and watched its leaves unfold.",
      },
      {
        id: "moonlight-page-5",
        imagePath: "assets/images/lumi_fox.png",
        text: "By moonrise, a bright flower sparkled in the garden.",
      },
    ],
  };
}

async function createSampleStoryForUser({firestore, userId}) {
  const profileRef = firestore.collection("userProfiles").doc(userId);
  const profileSnapshot = await profileRef.get();
  if (!profileSnapshot.exists ||
      profileSnapshot.data()?.onboardingCompleted !== true) {
    const error = new Error("The user profile is not ready.");
    error.code = "profile-not-ready";
    throw error;
  }

  const storyRef = profileRef
      .collection("stories")
      .doc(PERSONALIZED_STORY_ID);
  const existingStory = await storyRef.get();
  if (existingStory.exists) return PERSONALIZED_STORY_ID;

  const timestamp = FieldValue.serverTimestamp();
  await storyRef.set({
    ...buildSampleStory(),
    createdAt: timestamp,
    updatedAt: timestamp,
  });
  return PERSONALIZED_STORY_ID;
}

module.exports = {
  PERSONALIZED_STORY_ID,
  buildSampleStory,
  createSampleStoryForUser,
};
