const {readFileSync} = require("node:fs");
const test = require("node:test");

const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {doc, getDoc, setDoc} = require("firebase/firestore");

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
