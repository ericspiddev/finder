// test.js - synthetic JavaScript file for syntax testing
"use strict";

/* Constants */
const APP_NAME = "JsTestApp";
const VERSION = 1.0;
const MAX_ITEMS = 10;

/* Utility */
function log(...args) {
  console.log(`[${APP_NAME}]`, ...args);
}

/* Enum-like object */
const State = Object.freeze({
  INIT: 0,
  RUNNING: 1,
  STOPPED: 2
});

/* Symbols */
const PRIVATE_ID = Symbol("privateId");

/* Class */
class Node {
  constructor(id = 0, name = "unnamed") {
    this.id = id;
    this.name = name;
    this.value = 0;
    this.next = null;
    this[PRIVATE_ID] = Math.random();
  }

  setValue(v) {
    this.value = v ?? 0; // nullish coalescing
  }

  toString() {
    return `Node{id=${this.id}, name=${this.name}, value=${this.value}}`;
  }

  static fromObject({ id, name }) {
    return new Node(id, name);
  }
}

/* Prototype extension */
Node.prototype.reset = function () {
  this.value = 0;
};

/* Linked list helpers */
function appendNode(head, node) {
  if (!head) return node;

  let cur = head;
  while (cur?.next) {           // optional chaining
    cur = cur.next;
  }
  cur.next = node;
  return head;
}

/* Generator */
function* iterateNodes(head) {
  let cur = head;
  while (cur) {
    yield cur;
    cur = cur.next;
  }
}

/* Async / Promise */
async function fakeApiCall(data) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        ok: true,
        data,
        timestamp: Date.now()
      });
    }, 200);
  });
}

/* IIFE */
(function init() {
  log("initializing module");
})();

/* Main */
async function main(...args) {
  let state = State.INIT;
  log("args:", args.length);

  /* Arrays */
  const numbers = Array.from({ length: MAX_ITEMS }, (_, i) => i ** 2);

  const doubled = numbers
    .filter(n => n % 2 === 0)
    .map(n => n * 2);

  for (const [index, value] of doubled.entries()) {
    log(`doubled[${index}] =`, value);
  }

  /* Destructuring + spread */
  const [first, ...rest] = doubled;
  log("first:", first, "rest:", rest);

  /* Maps & Sets */
  const map = new Map();
  const set = new Set(rest);

  set.forEach(v => map.set(v, { squared: v ** 2 }));

  /* Linked list */
  let head = null;
  head = appendNode(head, new Node(1, "alpha"));
  head = appendNode(head, Node.fromObject({ id: 2, name: "beta" }));
  head = appendNode(head, new Node(3, "gamma"));

  for (const node of iterateNodes(head)) {
    node.setValue(node.id * 10);
    log(node.toString());
  }

  /* Async */
  const response = await fakeApiCall({ count: map.size });
  log("api response:", response?.data ?? {});

  /* Error handling */
  try {
    JSON.parse("{ broken json ");
  } catch (err) {
    log("caught error:", err.message);
  } finally {
    log("cleanup done");
  }

  state = State.STOPPED;
  return state;
}

/* Run */
main("foo", "bar", 42)
  .then(state => log("final state =", state))
  .catch(err => log("unhandled error:", err));

