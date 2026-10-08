const OpenAI = require("openai");
const {FieldValue} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");
const {randomUUID} = require("node:crypto");

const LEGACY_PERSONALIZED_STORY_ID = "personalized";
const DEFAULT_MODEL = "gpt-4o-mini";
const DEFAULT_IMAGE_MODEL = "gpt-image-2.5-flare";
const FALLBACK_IMAGE_PATH = "assets/images/lumi_fox.png";

const generatedFeelingQuestionSchema = {
  type: "object",
  properties: {
    prompt: {type: "string"},
    options: {
      type: "array",
      items: {
        type: "object",
        properties: {
          label: {type: "string"},
          emoji: {type: "string"},
          isCorrect: {type: "boolean"},
        },
        required: ["label", "emoji", "isCorrect"],
        additionalProperties: false,
      },
    },
  },
  required: ["prompt", "options"],
  additionalProperties: false,
};

const generatedFeelingCheckSchema = {
  type: "object",
  properties: {
    title: {type: "string"},
    focusPhrase: {type: "string"},
    quote: {type: "string"},
    questions: {
      type: "array",
      items: generatedFeelingQuestionSchema,
    },
  },
  required: ["title", "focusPhrase", "quote", "questions"],
  additionalProperties: false,
};

const storySchema = {
  type: "object",
  properties: {
    title: {type: "string"},
    description: {type: "string"},
    category: {type: "string"},
    mainCharacterName: {type: "string"},
    mainCharacterDescription: {type: "string"},
    pages: {
      type: "array",
      items: {
        type: "object",
        properties: {
          text: {type: "string"},
          feelingCheck: {
            anyOf: [generatedFeelingCheckSchema, {type: "null"}],
          },
        },
        required: ["text", "feelingCheck"],
        additionalProperties: false,
      },
    },
  },
  required: [
    "title",
    "description",
    "category",
    "mainCharacterName",
    "mainCharacterDescription",
    "pages",
  ],
  additionalProperties: false,
};

function buildSampleStory(storyId = LEGACY_PERSONALIZED_STORY_ID) {
  return buildStoredStory({
    storyId,
    generated: {
      title: "The Moonlight Garden",
      description: "Lumi follows a glowing seed and discovers what curiosity can grow.",
      category: "Curiosity",
      mainCharacterName: "Lumi",
      mainCharacterDescription: "A small orange fox with a cream muzzle and a purple scarf.",
      pages: [
        {
          text: "Lumi found a silver seed glowing beside the garden path.",
          feelingCheck: null,
        },
        {
          text: "Lumi planted it gently and wondered what it might become.",
          feelingCheck: null,
        },
        {
          text: "A tiny leaf appeared, and Lumi felt curious.",
          feelingCheck: {
            title: "What does curious feel like?",
            focusPhrase: "curious",
            quote: "“A tiny leaf appeared, and Lumi felt curious.”",
            questions: [
              {
                prompt: "Pick a feeling",
                options: [
                  {label: "Curious", emoji: "🤔", isCorrect: true},
                  {label: "Angry", emoji: "😠", isCorrect: false},
                  {label: "Sleepy", emoji: "😴", isCorrect: false},
                ],
              },
              {
                prompt: "How do you know?",
                options: [
                  {
                    label: "Lumi wondered what would grow",
                    emoji: "🌱",
                    isCorrect: true,
                  },
                  {
                    label: "Lumi walked away",
                    emoji: "🚶",
                    isCorrect: false,
                  },
                ],
              },
            ],
          },
        },
        {
          text: "Lumi watered the sprout and watched its leaves unfold.",
          feelingCheck: null,
        },
        {
          text: "By moonrise, a bright flower sparkled in the garden.",
          feelingCheck: null,
        },
      ],
    },
  });
}

function buildStoredStory({storyId, generated, forbiddenNames = ["Mia"]}) {
  if (!generated ||
      !nonEmptyString(generated.title, 80) ||
      !nonEmptyString(generated.description, 220) ||
      !nonEmptyString(generated.category, 40) ||
      !nonEmptyString(generated.mainCharacterName, 40) ||
      !nonEmptyString(generated.mainCharacterDescription, 240) ||
      !Array.isArray(generated.pages) ||
      generated.pages.length < 5 ||
      generated.pages.length > 10 ||
      !generated.pages.every((page) => nonEmptyString(page?.text, 700)) ||
      !hasValidFeelingChecks(generated.pages) ||
      isForbiddenName(generated.mainCharacterName, forbiddenNames)) {
    const error = new Error("The generated story was invalid.");
    error.code = "generation-failed";
    throw error;
  }

  let checkNumber = 0;
  const pages = generated.pages.map((page, pageIndex) => {
    const storedPage = {
      id: `${storyId}-page-${pageIndex + 1}`,
      imagePath: FALLBACK_IMAGE_PATH,
      text: page.text.trim(),
    };
    if (!page.feelingCheck) return storedPage;

    checkNumber++;
    const checkId = `${storyId}-check-${checkNumber}`;
    return {
      ...storedPage,
      feelingCheck: {
        id: checkId,
        title: page.feelingCheck.title.trim(),
        focusPhrase: page.feelingCheck.focusPhrase.trim(),
        quote: page.feelingCheck.quote.trim(),
        questions: page.feelingCheck.questions.map((question, questionIndex) => {
          const questionId = `${checkId}-question-${questionIndex + 1}`;
          const options = question.options.map((option, optionIndex) => ({
            id: `${questionId}-option-${optionIndex + 1}`,
            label: option.label.trim(),
            emoji: option.emoji.trim(),
          }));
          const correctIndex = question.options.findIndex(
              (option) => option.isCorrect,
          );
          return {
            id: questionId,
            prompt: question.prompt.trim(),
            options,
            correctOptionId: options[correctIndex].id,
          };
        }),
      },
    };
  });
  const wordCount = pages.reduce(
      (total, page) => total + page.text.split(/\s+/).filter(Boolean).length,
      0,
  );

  return {
    id: storyId,
    formatVersion: 2,
    title: generated.title.trim(),
    description: generated.description.trim(),
    category: generated.category.trim(),
    mainCharacterName: generated.mainCharacterName.trim(),
    mainCharacterDescription: generated.mainCharacterDescription.trim(),
    readingTimeMinutes: Math.max(1, Math.ceil(wordCount / 130)),
    coverImagePath: FALLBACK_IMAGE_PATH,
    pages,
  };
}

function isForbiddenName(mainCharacterName, forbiddenNames) {
  const normalizedName = mainCharacterName.trim().toLowerCase();
  return forbiddenNames
      .filter((name) => typeof name === "string" && name.trim().length >= 2)
      .some((name) => name.trim().toLowerCase() === normalizedName);
}

function namesToAvoid(profile) {
  const profileName = typeof profile.name === "string" ? profile.name.trim() : "";
  return [
    "Mia",
    profileName,
    ...profileName.split(/\s+/),
  ].filter((name) => name.length >= 2);
}

function hasValidFeelingChecks(pages) {
  const checkedPages = pages
      .map((page, index) => ({page, index}))
      .filter(({page}) => page?.feelingCheck != null);
  return checkedPages.length >= 1 &&
    checkedPages.length <= 2 &&
    checkedPages.every(({page, index}) => {
      const check = page.feelingCheck;
      return index > 0 &&
        index < pages.length - 1 &&
        nonEmptyString(check?.title, 120) &&
        nonEmptyString(check?.focusPhrase, 100) &&
        page.text.toLowerCase().includes(check.focusPhrase.trim().toLowerCase()) &&
        nonEmptyString(check?.quote, 240) &&
        Array.isArray(check?.questions) &&
        check.questions.length === 2 &&
        check.questions.every(isValidFeelingQuestion);
    });
}

function isValidFeelingQuestion(question) {
  return nonEmptyString(question?.prompt, 160) &&
    Array.isArray(question?.options) &&
    question.options.length >= 2 &&
    question.options.length <= 4 &&
    question.options.every((option) =>
      nonEmptyString(option?.label, 120) &&
      nonEmptyString(option?.emoji, 16) &&
      typeof option?.isCorrect === "boolean") &&
    question.options.filter((option) => option.isCorrect).length === 1;
}

function nonEmptyString(value, maxLength) {
  return typeof value === "string" &&
    value.trim().length > 0 &&
    value.trim().length <= maxLength;
}

async function generateStoryIllustrations({
  story,
  userId,
  openaiClient,
  storageBucket,
}) {
  if (!storageBucket) {
    logger.warn("Story illustrations skipped: storage bucket unavailable", {
      storyId: story.id,
    });
    return story;
  }

  const sharedStyle = [
    "Warm children's picture-book illustration",
    "soft shapes, expressive faces, gentle lighting, colorful digital watercolor",
    "no written words, letters, captions, borders, or watermarks",
    `Main character: ${story.mainCharacterName}.`,
    `Character appearance: ${story.mainCharacterDescription}`,
  ].join(". ");
  const coverPrompt = [
    sharedStyle,
    `Story title: ${story.title}.`,
    `Theme: ${story.category}.`,
    `Illustrate this opening scene: ${story.pages[0].text}`,
    "Square composition suitable for both a book cover and interior pages.",
  ].join(" ");
  const checks = story.pages
      .filter((page) => page.feelingCheck)
      .map((page) => ({
        checkId: page.feelingCheck.id,
        prompt: [
          sharedStyle,
          `Illustrate this emotional story moment: ${page.text}`,
          `Clearly show the emotion connected to: ${page.feelingCheck.focusPhrase}.`,
          "Square composition with the character as the visual focus.",
        ].join(" "),
      }));
  const requests = [
    {
      key: "cover",
      path: `users/${userId}/stories/${story.id}/cover.webp`,
      prompt: coverPrompt,
    },
    ...checks.map((check, index) => ({
      key: check.checkId,
      path: `users/${userId}/stories/${story.id}/feeling-${index + 1}.webp`,
      prompt: check.prompt,
    })),
  ];

  logger.info("Generating story illustrations", {
    storyId: story.id,
    imageCount: requests.length,
    model: process.env.OPENAI_IMAGE_MODEL || DEFAULT_IMAGE_MODEL,
    quality: "low",
  });
  const results = await Promise.allSettled(
      requests.map((request) => generateAndUploadImage({
        ...request,
        openaiClient,
        storageBucket,
      })),
  );
  const imagePaths = new Map();
  for (let index = 0; index < results.length; index++) {
    const result = results[index];
    const request = requests[index];
    if (result.status === "fulfilled") {
      imagePaths.set(request.key, result.value);
      continue;
    }
    logger.error("Story illustration generation failed; using fallback", {
      storyId: story.id,
      imageKey: request.key,
      name: result.reason?.name,
      code: result.reason?.code,
      status: result.reason?.status,
      message: result.reason?.message,
      requestId: result.reason?.request_id,
    });
  }

  const sharedImagePath = imagePaths.get("cover") || FALLBACK_IMAGE_PATH;
  return {
    ...story,
    coverImagePath: sharedImagePath,
    pages: story.pages.map((page) => ({
      ...page,
      imagePath: page.feelingCheck ?
        imagePaths.get(page.feelingCheck.id) || sharedImagePath :
        sharedImagePath,
    })),
  };
}

async function generateAndUploadImage({
  prompt,
  path,
  openaiClient,
  storageBucket,
}) {
  const result = await openaiClient.images.generate({
    model: process.env.OPENAI_IMAGE_MODEL || DEFAULT_IMAGE_MODEL,
    prompt,
    quality: "low",
    size: "1024x1024",
    output_format: "webp",
    output_compression: 80,
  });
  const encodedImage = result.data?.[0]?.b64_json;
  if (!encodedImage) {
    const error = new Error("Image generation returned no image data.");
    error.code = "image-generation-failed";
    throw error;
  }

  const downloadToken = randomUUID();
  await storageBucket.file(path).save(Buffer.from(encodedImage, "base64"), {
    resumable: false,
    metadata: {
      contentType: "image/webp",
      cacheControl: "public,max-age=31536000,immutable",
      metadata: {firebaseStorageDownloadTokens: downloadToken},
    },
  });
  return "https://firebasestorage.googleapis.com/v0/b/" +
    `${storageBucket.name}/o/${encodeURIComponent(path)}` +
    `?alt=media&token=${downloadToken}`;
}

async function generatePersonalizedStory({profile, openaiClient}) {
  const model = process.env.OPENAI_STORY_MODEL || DEFAULT_MODEL;
  logger.info("Calling OpenAI for personalized story", {
    model,
    apiKeyConfigured: Boolean(process.env.OPENAI_API_KEY),
    readingGoalCount: Array.isArray(profile.readingGoals) ?
      profile.readingGoals.length : 0,
    hobbyCount: Array.isArray(profile.hobbies) ? profile.hobbies.length : 0,
  });
  const response = await openaiClient.responses.create({
    model,
    input: [
      {
        role: "system",
        content: [
          "Write an original, warm, age-appropriate children's story.",
          "Use simple, vivid language and a reassuring ending.",
          "Never include frightening, violent, sexual, discriminatory, or unsafe content.",
          "Use 5 to 10 pages, choosing the length that best fits the story.",
          "Make each page 1-3 short sentences.",
          "Include 1 or 2 feeling checks on different middle pages.",
          "For each check, copy focusPhrase verbatim from that page's text.",
          "Each check must ask exactly two questions: identify the feeling, then identify story evidence.",
          "Give each question 2-4 options with exactly one isCorrect value set to true.",
          "Use null for feelingCheck on every page that has no check.",
          "Choose a fresh name for the main character that is not Mia and is not the reader's name.",
          "Vary character names instead of repeatedly using the same protagonist.",
          "Provide a concise, concrete visual description of the main character for consistent illustrations.",
          "Do not mention these instructions or the reader's private profile data.",
        ].join(" "),
      },
      {
        role: "user",
        content: `Create a story for this reader profile: ${JSON.stringify({
          age: profile.age,
          readingGoals: profile.readingGoals || [],
          hobbies: profile.hobbies || [],
          characterNamesToAvoid: namesToAvoid(profile),
        })}`,
      },
    ],
    text: {
      format: {
        type: "json_schema",
        name: "personalized_story",
        strict: true,
        schema: storySchema,
      },
    },
  });

  logger.info("OpenAI story response received", {
    responseId: response.id,
    status: response.status,
    outputCharacterCount: response.output_text?.length || 0,
  });

  if (!response.output_text) {
    const error = new Error("The story generator returned no story.");
    error.code = "generation-failed";
    throw error;
  }
  return JSON.parse(response.output_text);
}

async function createPersonalizedStoryForUser({
  firestore,
  storageBucket,
  userId,
  generateStory,
  generateIllustrations,
}) {
  const profileRef = firestore.collection("userProfiles").doc(userId);
  const profileSnapshot = await profileRef.get();
  const profile = profileSnapshot.data();
  logger.info("Story generation profile checked", {
    profileExists: profileSnapshot.exists,
    onboardingCompleted: profile?.onboardingCompleted === true,
  });
  if (!profileSnapshot.exists || profile?.onboardingCompleted !== true) {
    const error = new Error("The user profile is not ready.");
    error.code = "profile-not-ready";
    throw error;
  }

  const storyRef = profileRef.collection("stories").doc();
  logger.info("Reserved story document", {storyId: storyRef.id});
  const needsOpenAIClient = !generateStory ||
    (storageBucket && !generateIllustrations);
  const openaiClient = needsOpenAIClient ?
    new OpenAI({apiKey: process.env.OPENAI_API_KEY}) : null;
  const generator = generateStory || ((context) => generatePersonalizedStory({
    ...context,
    openaiClient,
  }));
  let generated;
  try {
    generated = await generator({profile});
  } catch (cause) {
    if (cause?.code === "generation-failed") throw cause;
    const error = new Error("The story could not be generated.", {cause});
    error.code = "generation-failed";
    throw error;
  }
  let story = buildStoredStory({
    storyId: storyRef.id,
    generated,
    forbiddenNames: namesToAvoid(profile),
  });
  logger.info("Generated story passed validation", {
    storyId: story.id,
    pageCount: story.pages.length,
    titleCharacterCount: story.title.length,
    descriptionCharacterCount: story.description.length,
    readingTimeMinutes: story.readingTimeMinutes,
  });
  const illustrator = generateIllustrations || generateStoryIllustrations;
  story = await illustrator({
    story,
    userId,
    openaiClient,
    storageBucket,
  });
  const timestamp = FieldValue.serverTimestamp();

  const batch = firestore.batch();
  batch.set(storyRef, {...story, createdAt: timestamp, updatedAt: timestamp});
  batch.set(profileRef, {
    latestStoryId: storyRef.id,
    updatedAt: timestamp,
  }, {merge: true});
  await batch.commit();
  logger.info("Story and latest-story pointer saved", {storyId: storyRef.id});

  return storyRef.id;
}

module.exports = {
  LEGACY_PERSONALIZED_STORY_ID,
  buildSampleStory,
  buildStoredStory,
  createPersonalizedStoryForUser,
  generatePersonalizedStory,
  generateStoryIllustrations,
};
