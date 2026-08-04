"use strict";

const fs = require("fs");
const vm = require("vm");

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

class FakeEvent {
  constructor(type, options = {}) {
    this.type = type;
    this.bubbles = options.bubbles === true;
    this.defaultPrevented = false;
    this.propagationStopped = false;
    this.key = options.key || "";
  }

  preventDefault() { this.defaultPrevented = true; }
  stopPropagation() { this.propagationStopped = true; }
}

class FakeElement {
  constructor(name) {
    this.name = name;
    this.checked = false;
    this.dataset = {};
    this.attributes = new Map();
    this.listeners = new Map();
    this.focused = false;
    this.control = null;
  }

  setAttribute(name, value) { this.attributes.set(name, String(value)); }
  getAttribute(name) { return this.attributes.get(name) ?? null; }
  hasAttribute(name) { return this.attributes.has(name); }
  removeAttribute(name) { this.attributes.delete(name); }

  addEventListener(type, listener) {
    const listeners = this.listeners.get(type) || new Set();
    listeners.add(listener);
    this.listeners.set(type, listeners);
  }

  removeEventListener(type, listener) {
    const listeners = this.listeners.get(type);
    if (listeners) listeners.delete(listener);
  }

  dispatchEvent(event) {
    for (const listener of [...(this.listeners.get(event.type) || [])]) listener(event);
    return !event.defaultPrevented;
  }

  click() {
    if (!this.control) return;
    this.control.checked = !this.control.checked;
    this.control.dispatchEvent(new FakeEvent("change", { bubbles: true }));
  }

  focus() { this.focused = true; }
  listenerCount(type) { return (this.listeners.get(type) || new Set()).size; }
}

const controls = new Map();
const labels = new Map();
const documentListeners = new Map();

const document = {
  readyState: "complete",
  documentElement: {},
  getElementById(id) { return controls.get(id) || null; },
  querySelector(selector) {
    const match = selector.match(/for="([^"]+)"/);
    return match ? labels.get(match[1]) || null : null;
  },
  addEventListener(type, listener) {
    const listeners = documentListeners.get(type) || new Set();
    listeners.add(listener);
    documentListeners.set(type, listeners);
  },
  dispatchEvent(event) {
    for (const listener of [...(documentListeners.get(event.type) || [])]) listener(event);
  },
};

class FakeMutationObserver {
  constructor(callback) { this.callback = callback; this.connected = false; }
  observe() { this.connected = true; }
  disconnect() { this.connected = false; }
}

let instantNavigationHandler = null;
const document$ = {
  subscribe(handler) { instantNavigationHandler = handler; },
};

function installPair(id) {
  const control = new FakeElement(`${id}-control`);
  const label = new FakeElement(`${id}-label`);
  label.control = control;
  controls.set(id, control);
  labels.set(id, label);
  return { control, label };
}

function key(target, value) {
  const event = new FakeEvent("keydown", { key: value });
  target.dispatchEvent(event);
  return event;
}

Object.assign(globalThis, {
  document,
  document$,
  MutationObserver: FakeMutationObserver,
  Event: FakeEvent,
});

let drawer = installPair("__drawer");
let search = installPair("__search");
const source = fs.readFileSync(process.argv[2], "utf8");
vm.runInThisContext(source, { filename: process.argv[2] });
assert(typeof instantNavigationHandler === "function", "instant-navigation subscription was not registered");
instantNavigationHandler();

assert(drawer.label.getAttribute("role") === "button", "drawer label did not become a button");
assert(drawer.label.getAttribute("tabindex") === "0", "drawer label is not keyboard focusable");
assert(drawer.label.getAttribute("aria-controls") === "__drawer", "drawer aria-controls is wrong");
assert(drawer.label.getAttribute("aria-expanded") === "false", "drawer initial state is wrong");
assert(drawer.label.getAttribute("aria-label") === "Open navigation", "drawer initial name is wrong");
assert(!drawer.label.hasAttribute("aria-haspopup"), "drawer must not claim popup-menu semantics");
assert(search.label.getAttribute("aria-haspopup") === "dialog", "search must expose dialog semantics");

let event = key(drawer.label, "Enter");
assert(event.defaultPrevented && event.propagationStopped, "Enter was not consumed");
assert(drawer.control.checked, "Enter did not open the drawer");
assert(drawer.label.getAttribute("aria-expanded") === "true", "drawer expanded state did not synchronize");
assert(drawer.label.getAttribute("aria-label") === "Close navigation", "drawer open name did not synchronize");

event = key(drawer.label, " ");
assert(event.defaultPrevented && !drawer.control.checked, "Space did not close the drawer");
assert(drawer.label.getAttribute("aria-label") === "Open navigation", "drawer close name did not synchronize");

key(search.label, "Enter");
assert(search.control.checked, "Enter did not open search");
const escape = new FakeEvent("keydown", { key: "Escape" });
document.dispatchEvent(escape);
assert(escape.defaultPrevented, "Escape was not consumed");
assert(!search.control.checked, "Escape did not close search");
assert(search.label.focused, "Escape did not restore focus to search");
assert(search.label.getAttribute("aria-label") === "Open search", "search close name did not synchronize");

instantNavigationHandler();
instantNavigationHandler();
assert(drawer.label.listenerCount("keydown") === 1, "repeat enhancement duplicated drawer listeners");
assert(drawer.control.listenerCount("change") === 1, "repeat enhancement duplicated control listeners");

const originalDrawerControl = drawer.control;
const replacementDrawerControl = new FakeElement("replacement-drawer-control");
controls.set("__drawer", replacementDrawerControl);
drawer.label.control = replacementDrawerControl;
instantNavigationHandler();
assert(originalDrawerControl.listenerCount("change") === 0, "replaced control kept a stale listener");
assert(drawer.label.listenerCount("keydown") === 1, "control replacement duplicated label listeners");
assert(replacementDrawerControl.listenerCount("change") === 1, "replacement control was not enhanced");

const oldDrawerLabel = drawer.label;
drawer = installPair("__drawer");
search = installPair("__search");
instantNavigationHandler();
assert(drawer.label !== oldDrawerLabel, "instant navigation did not replace the label fixture");
assert(drawer.label.listenerCount("keydown") === 1, "new drawer label was not enhanced exactly once");
assert(search.label.listenerCount("keydown") === 1, "new search label was not enhanced exactly once");
assert(drawer.label.getAttribute("aria-label") === "Open navigation", "new drawer label was not synchronized");

console.log("docs accessibility behavior: PASS");
