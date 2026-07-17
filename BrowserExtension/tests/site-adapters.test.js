"use strict";

const assert = require("node:assert/strict");
const fixtures = require("./fixtures.json");
const adapters = require("../site-adapters.js");

function fakeElement(attributes) {
  return { attributes: Object.entries(attributes).map(([name, value]) => ({ name, value })) };
}

for (const fixture of fixtures) {
  assert.equal(adapters.roleForElement(fixture.site, fakeElement(fixture.attributes)), fixture.role,
    `${fixture.site} ${JSON.stringify(fixture.attributes)}`);
}

assert.equal(adapters.estimateTokens("12345678"), 2);
assert.equal(adapters.estimateTokens(""), 1);
assert.equal(adapters.forHost("example.com"), null);
assert.equal(adapters.shouldBaseline("/", "/", undefined), true);
assert.equal(adapters.shouldBaseline("/", "/c/new-chat", 0), false);
assert.equal(adapters.shouldBaseline("/c/old", "/c/reopened", 2), true);
assert.equal(adapters.shouldBaseline("/c/same", "/c/same", 2), false);
console.log(`site adapter fixtures passed (${fixtures.length})`);
