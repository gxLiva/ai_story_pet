const assert = require("node:assert/strict");
const test = require("node:test");

const {
  PERSONALIZED_STORY_ID,
  buildSampleStory,
  createSampleStoryForUser,
} = require("../story");

test("sample story matches the mobile story contract", () => {
  const story = buildSampleStory();

  assert.equal(story.id, PERSONALIZED_STORY_ID);
  assert.equal(story.pages.length, 5);
  const checkedPage = story.pages.find((page) => page.feelingCheck);
  assert.ok(checkedPage);
  assert.match(
      checkedPage.text.toLowerCase(),
      new RegExp(checkedPage.feelingCheck.focusPhrase.toLowerCase()),
  );
  for (const question of checkedPage.feelingCheck.questions) {
    assert.ok(
        question.options.some(
            (option) => option.id === question.correctOptionId,
        ),
    );
  }
});

test("creation requires a completed onboarding profile", async () => {
  const firestore = fakeFirestore({onboardingCompleted: false});

  await assert.rejects(
      createSampleStoryForUser({firestore, userId: "reader-1"}),
      (error) => error.code === "profile-not-ready",
  );
});

test("creation writes one stable personalized story", async () => {
  const firestore = fakeFirestore({onboardingCompleted: true});

  const storyId = await createSampleStoryForUser({
    firestore,
    userId: "reader-1",
  });
  await createSampleStoryForUser({firestore, userId: "reader-1"});

  assert.equal(storyId, PERSONALIZED_STORY_ID);
  assert.equal(firestore.writes.length, 1);
  assert.equal(
      firestore.writes[0].path,
      "userProfiles/reader-1/stories/personalized",
  );
  assert.equal(firestore.writes[0].data.id, PERSONALIZED_STORY_ID);
});

function fakeFirestore(profileData) {
  const documents = new Map([
    ["userProfiles/reader-1", profileData],
  ]);
  const writes = [];

  function document(path) {
    return {
      async get() {
        return {
          exists: documents.has(path),
          data: () => documents.get(path),
        };
      },
      async set(data) {
        documents.set(path, data);
        writes.push({path, data});
      },
      collection(name) {
        return collection(`${path}/${name}`);
      },
    };
  }

  function collection(path) {
    return {doc: (id) => document(`${path}/${id}`)};
  }

  return {writes, collection};
}
