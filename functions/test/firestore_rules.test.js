const {readFileSync} = require("node:fs");
const test = require("node:test");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  where,
} = require("firebase/firestore");

let environment;

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId: "demo-ai-story-pet",
    firestore: {
      host: "127.0.0.1",
      port: 8080,
      rules: readFileSync("firestore.rules", "utf8"),
    },
  });

  await environment.withSecurityRulesDisabled(async (context) => {
    await setDoc(
        doc(
            context.firestore(),
            "userProfiles/reader-1/stories/personalized",
        ),
        {id: "personalized", title: "Test story"},
    );
    await setDoc(
        doc(context.firestore(), "stories/shared-story"),
        {id: "shared-story", title: "Shared story", published: true},
    );
    await setDoc(
        doc(context.firestore(), "stories/draft-story"),
        {id: "draft-story", title: "Draft story", published: false},
    );
  });
});

test.after(async () => {
  await environment.cleanup();
});

test("a reader can read their own story", async () => {
  const database = environment.authenticatedContext("reader-1").firestore();

  await assertSucceeds(
      getDoc(doc(database, "userProfiles/reader-1/stories/personalized")),
  );
});

test("another reader cannot read the story", async () => {
  const database = environment.authenticatedContext("reader-2").firestore();

  await assertFails(
      getDoc(doc(database, "userProfiles/reader-1/stories/personalized")),
  );
});

test("a signed-out reader cannot read the story", async () => {
  const database = environment.unauthenticatedContext().firestore();

  await assertFails(
      getDoc(doc(database, "userProfiles/reader-1/stories/personalized")),
  );
});

test("a mobile client cannot write a generated story", async () => {
  const database = environment.authenticatedContext("reader-1").firestore();

  await assertFails(
      setDoc(
          doc(database, "userProfiles/reader-1/stories/another-story"),
          {id: "another-story"},
      ),
  );
});

test("a reader can store and read only their own reading progress", async () => {
  const readerDatabase = environment
      .authenticatedContext("reader-1")
      .firestore();
  const otherDatabase = environment
      .authenticatedContext("reader-2")
      .firestore();
  const progressPath = "userProfiles/reader-1/readingProgress/shared-story";

  await assertSucceeds(
      setDoc(doc(readerDatabase, progressPath), {
        storyId: "shared-story",
        currentPageIndex: 2,
        completed: false,
      }),
  );
  await assertSucceeds(getDoc(doc(readerDatabase, progressPath)));
  await assertFails(getDoc(doc(otherDatabase, progressPath)));
  await assertFails(
      setDoc(doc(otherDatabase, progressPath), {completed: true}),
  );
});

test("a reader can store and read only their own practice progress", async () => {
  const readerDatabase = environment
      .authenticatedContext("reader-1")
      .firestore();
  const otherDatabase = environment
      .authenticatedContext("reader-2")
      .firestore();
  const progressPath = "userProfiles/reader-1/practiceProgress/shared-story";

  await assertSucceeds(
      setDoc(doc(readerDatabase, progressPath), {
        storyId: "shared-story",
        selectedActionId: "ask-for-help",
        completed: true,
      }),
  );
  await assertSucceeds(getDoc(doc(readerDatabase, progressPath)));
  await assertFails(getDoc(doc(otherDatabase, progressPath)));
  await assertFails(
      setDoc(doc(otherDatabase, progressPath), {completed: true}),
  );
});

test("an authenticated reader can read a published shared story", async () => {
  const database = environment.authenticatedContext("reader-2").firestore();

  await assertSucceeds(getDoc(doc(database, "stories/shared-story")));
});

test("an authenticated reader can list published shared stories", async () => {
  const database = environment.authenticatedContext("reader-2").firestore();
  const publishedStories = query(
      collection(database, "stories"),
      where("published", "==", true),
  );

  await assertSucceeds(getDocs(publishedStories));
});

test("a signed-out reader cannot read a shared story", async () => {
  const database = environment.unauthenticatedContext().firestore();

  await assertFails(getDoc(doc(database, "stories/shared-story")));
});

test("a reader cannot read an unpublished shared story", async () => {
  const database = environment.authenticatedContext("reader-1").firestore();

  await assertFails(getDoc(doc(database, "stories/draft-story")));
});

test("a mobile client cannot publish a shared story", async () => {
  const database = environment.authenticatedContext("reader-1").firestore();

  await assertFails(
      setDoc(doc(database, "stories/client-story"), {
        id: "client-story",
        title: "Client story",
        published: true,
      }),
  );
});
