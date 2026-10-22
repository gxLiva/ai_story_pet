const assert = require("node:assert/strict");
const test = require("node:test");

const {
  LEGACY_PERSONALIZED_STORY_ID,
  buildSampleStory,
  buildStoredStory,
  createPersonalizedStoryForUser,
  ensureSharedThemeStories,
  generateStoryIllustrations,
} = require("../story");

test("sample story matches the mobile story contract", () => {
  const story = buildSampleStory();

  assert.equal(story.id, LEGACY_PERSONALIZED_STORY_ID);
  assert.equal(story.formatVersion, 2);
  assert.ok(story.description);
  assert.ok(story.readingTimeMinutes > 0);
  assert.equal(story.practice.actions.length, 4);
  assert.equal(story.pages.length, 5);
  assert.equal(
      story.pages.filter((page) => page.feelingCheck).length,
      1,
  );
  for (const page of story.pages) {
    assert.ok(page.id.startsWith(LEGACY_PERSONALIZED_STORY_ID));
    assert.ok(page.text);
  }
});

test("generated stories support variable length and feeling checks", () => {
  const story = buildStoredStory({
    storyId: "variable-story",
    generated: fakeGeneratedStory(8),
  });

  assert.equal(story.pages.length, 8);
  const checkedPage = story.pages.find((page) => page.feelingCheck);
  assert.ok(checkedPage);
  assert.ok(
      checkedPage.text.toLowerCase().includes(
          checkedPage.feelingCheck.focusPhrase.toLowerCase(),
      ),
  );
  assert.equal(checkedPage.feelingCheck.questions.length, 2);
  for (const question of checkedPage.feelingCheck.questions) {
    assert.ok(
        question.options.some(
            (option) => option.id === question.correctOptionId,
        ),
    );
  }
});

test("generated stories reject invalid length or missing checks", () => {
  assert.throws(
      () => buildStoredStory({
        storyId: "too-short",
        generated: fakeGeneratedStory(4),
      }),
      (error) => error.code === "generation-failed",
  );
  const noChecks = fakeGeneratedStory(5);
  noChecks.pages.forEach((page) => {
    page.feelingCheck = null;
  });
  assert.throws(
      () => buildStoredStory({storyId: "no-checks", generated: noChecks}),
      (error) => error.code === "generation-failed",
  );
});

test("generated stories reject Mia and the reader's name", () => {
  const miaStory = fakeGeneratedStory(5);
  miaStory.mainCharacterName = "Mia";
  assert.throws(
      () => buildStoredStory({storyId: "mia-story", generated: miaStory}),
      (error) => error.code === "generation-failed",
  );

  const readerStory = fakeGeneratedStory(5);
  readerStory.mainCharacterName = "Olivia";
  assert.throws(
      () => buildStoredStory({
        storyId: "reader-name-story",
        generated: readerStory,
        forbiddenNames: ["Mia", "Olivia"],
      }),
      (error) => error.code === "generation-failed",
  );
});

test("illustrations share a cover image and replace feeling-check images", async () => {
  const calls = [];
  const saves = [];
  const openaiClient = {
    images: {
      async generate(options) {
        calls.push(options);
        return {data: [{b64_json: Buffer.from("image").toString("base64")}]};
      },
    },
  };
  const storageBucket = {
    name: "test-bucket",
    file(path) {
      return {
        async save(data, options) {
          saves.push({path, data, options});
        },
      };
    },
  };
  const story = buildStoredStory({
    storyId: "illustrated-story",
    generated: fakeGeneratedStory(7),
  });

  const illustrated = await generateStoryIllustrations({
    story,
    userId: "reader-1",
    openaiClient,
    storageBucket,
  });

  assert.equal(calls.length, 2);
  assert.ok(calls.every((call) => call.quality === "low"));
  assert.equal(saves.length, 2);
  assert.match(illustrated.coverImagePath, /^https:\/\//);
  const checkedPage = illustrated.pages.find((page) => page.feelingCheck);
  assert.notEqual(checkedPage.imagePath, illustrated.coverImagePath);
  assert.ok(
      illustrated.pages
          .filter((page) => !page.feelingCheck)
          .every((page) => page.imagePath === illustrated.coverImagePath),
  );
});

test("creation requires a completed onboarding profile", async () => {
  const firestore = fakeFirestore({onboardingCompleted: false});

  await assert.rejects(
      createPersonalizedStoryForUser({
        firestore,
        userId: "reader-1",
        generateStory: fakeGenerator,
      }),
      (error) => error.code === "profile-not-ready",
  );
});

test("each creation preserves the story and updates the latest pointer", async () => {
  const firestore = fakeFirestore({onboardingCompleted: true});

  const firstStoryId = await createPersonalizedStoryForUser({
    firestore,
    userId: "reader-1",
    generateStory: fakeGenerator,
  });
  const secondStoryId = await createPersonalizedStoryForUser({
    firestore,
    userId: "reader-1",
    generateStory: fakeGenerator,
  });

  assert.notEqual(firstStoryId, secondStoryId);
  const storyWrites = firestore.writes.filter(
      (write) => write.path.includes("/stories/"),
  );
  assert.equal(storyWrites.length, 2);
  assert.deepEqual(
      storyWrites.map((write) => write.data.id),
      [firstStoryId, secondStoryId],
  );
  assert.equal(
      firestore.documents.get("userProfiles/reader-1").latestStoryId,
      secondStoryId,
  );
  const sharedWrites = firestore.writes.filter(
      (write) => write.path.startsWith("stories/"),
  );
  assert.equal(sharedWrites.length, 2);
  assert.ok(sharedWrites.every((write) => write.data.published === true));
  assert.ok(sharedWrites.every(
      (write) => write.data.titleSearch === "a new adventure",
  ));
});

test("shared theme stories are generated once at stable ids", async () => {
  const firestore = fakeFirestore({onboardingCompleted: true});
  const generatedCategories = [];
  const illustrationPaths = [];
  const generateStory = async (category) => {
    generatedCategories.push(category);
    return {...fakeGeneratedStory(5), category};
  };
  const generateIllustrations = async ({story, storagePathPrefix}) => {
    illustrationPaths.push(storagePathPrefix);
    const coverImagePath = `https://images.test/${story.id}/cover.webp`;
    return {
      ...story,
      coverImagePath,
      pages: story.pages.map((page) => ({...page, imagePath: coverImagePath})),
    };
  };

  const first = await ensureSharedThemeStories({
    firestore,
    generateStory,
    generateIllustrations,
  });
  const second = await ensureSharedThemeStories({
    firestore,
    generateStory,
    generateIllustrations,
  });

  assert.deepEqual(generatedCategories.sort(), [
    "Big Feelings",
    "Courage",
    "Friendship",
    "Transition",
  ]);
  assert.equal(first.filter((result) => result.status === "created").length, 4);
  assert.equal(second.filter((result) => result.status === "existing").length, 4);
  assert.ok(illustrationPaths.every((path) => path.startsWith("shared/stories/theme-")));
  for (const category of generatedCategories) {
    const storyId = `theme-${category.toLowerCase().replace(/\s+/g, "-")}`;
    const saved = firestore.documents.get(`stories/${storyId}`);
    assert.equal(saved.category, category);
    assert.equal(saved.published, true);
    assert.equal(saved.generationStatus, "complete");
  }
});

test("shared theme stories retry invalid model responses", async () => {
  const firestore = fakeFirestore({onboardingCompleted: true});
  const attempts = new Map();

  await ensureSharedThemeStories({
    firestore,
    generateStory: async (category) => {
      const attempt = (attempts.get(category) || 0) + 1;
      attempts.set(category, attempt);
      return {...fakeGeneratedStory(attempt === 1 ? 4 : 5), category};
    },
    generateIllustrations: async ({story}) => story,
  });

  assert.deepEqual([...attempts.values()], [2, 2, 2, 2]);
});

async function fakeGenerator() {
  return fakeGeneratedStory(7);
}

function fakeGeneratedStory(pageCount) {
  return {
    title: "A New Adventure",
    description: "A short description.",
    category: "Friendship",
    mainCharacterName: "Noah",
    mainCharacterDescription: "A young explorer with curly hair and a green jacket.",
    practice: {
      situation: "Noah wonders how to join a new group.",
      prompt: "If you were Noah, what would you choose to do?",
      actions: [
        {
          label: "Say hello",
          emoji: "👋",
          feedback: "A greeting can open a conversation.",
          outcome: "Noah says hello and the group smiles back.",
        },
        {
          label: "Watch first",
          emoji: "👀",
          feedback: "Watching can help you feel ready.",
          outcome: "Noah learns what the group is doing.",
        },
        {
          label: "Ask for help",
          emoji: "🤝",
          feedback: "Support can make a new step easier.",
          outcome: "A friend helps Noah join the activity.",
        },
        {
          label: "Try later",
          emoji: "⏳",
          feedback: "It is okay to go at your own pace.",
          outcome: "Noah takes time and tries again later.",
        },
      ],
    },
    pages: Array.from({length: pageCount}, (_, index) => ({
      text: `Story page ${index + 1}.`,
      feelingCheck: index === 1 ? {
        title: "How did the character feel?",
        focusPhrase: "page 2",
        quote: "“Story page 2.”",
        questions: [
          {
            prompt: "Pick a feeling",
            options: [
              {label: "Curious", emoji: "🤔", isCorrect: true},
              {label: "Sleepy", emoji: "😴", isCorrect: false},
            ],
          },
          {
            prompt: "How do you know?",
            options: [
              {label: "They looked closer", emoji: "🔎", isCorrect: true},
              {label: "They left", emoji: "🚶", isCorrect: false},
            ],
          },
        ],
      } : null,
    })),
  };
}

function fakeFirestore(profileData) {
  const documents = new Map([
    ["userProfiles/reader-1", profileData],
  ]);
  const writes = [];
  let nextId = 1;

  function document(path) {
    return {
      async get() {
        return {
          exists: documents.has(path),
          data: () => documents.get(path),
        };
      },
      async set(data, options) {
        const nextData = options?.merge
          ? {...documents.get(path), ...data}
          : data;
        documents.set(path, nextData);
        writes.push({path, data});
      },
      async create(data) {
        if (documents.has(path)) {
          const error = new Error("Document already exists.");
          error.code = 6;
          throw error;
        }
        documents.set(path, data);
        writes.push({path, data});
      },
      async delete() {
        documents.delete(path);
      },
      collection(name) {
        return collection(`${path}/${name}`);
      },
    };
  }

  function collection(path) {
    return {
      doc(id) {
        const documentId = id || `generated-story-${nextId++}`;
        return {...document(`${path}/${documentId}`), id: documentId};
      },
    };
  }

  return {
    documents,
    writes,
    collection,
    batch() {
      const operations = [];
      return {
        set(reference, data, options) {
          operations.push({reference, data, options});
        },
        async commit() {
          for (const operation of operations) {
            await operation.reference.set(operation.data, operation.options);
          }
        },
      };
    },
  };
}
