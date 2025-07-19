import { test } from "node:test";
import assert from "node:assert";
import lambda from "./index.js";

function invokeHandler(uri) {
  return new Promise((res) => {
    const cb = (_, response) => {
      res(response);
    };

    lambda.handler(
      {
        Records: [
          {
            cf: {
              request: {
                uri,
              },
            },
          },
        ],
      },
      undefined,
      cb
    );
  });
}

test("example expected redirects", async (t) => {
  const redirects = [
    // root
    { from: "/", to: "https://www.rust-lang.org/learn" },
    { from: "/index.html", to: "https://www.rust-lang.org/learn" },
    // crate redirects
    { from: "/regex", to: "https://docs.rs/regex" },
    { from: "/log", to: "https://docs.rs/log" },
    { from: "/rand/0.9.1/rand/", to: "https://docs.rs/rand/0.9.1/rand/" },
    // trpl
    { from: "/trpl", to: "/stable/book" },
    { from: "/stable/trpl/hello", to: "/stable/book/hello" },
    { from: "/nightly/trpl", to: "/nightly/book" },
    // adv-book
    { from: "/adv-book", to: "/stable/nomicon" },
    { from: "/stable/adv-book/hello", to: "/stable/nomicon/hello" },
    { from: "/nightly/adv-book", to: "/nightly/nomicon" },
    // master
    { from: "/master/hello", to: "/nightly/hello" },
    // /doc
    { from: "/doc/std", to: "/std" },
    { from: "/doc/hello", to: "/hello" },
  ];

  for (const redir of redirects) {
    await t.test(`redirect ${redir.from}`, async (t) => {
      const response = await invokeHandler(redir.from);

      assert(["301", "302"].includes(response.status));

      const location = response.headers.location[0];
      assert.strictEqual(location.key, "Location");

      assert.strictEqual(location.value, redir.to);
    });
  }
});

test("ensure the default rewrite to /stable", async (t) => {
  const request = await invokeHandler("/std");
  assert.strictEqual(request.uri, "/stable/std");
});
