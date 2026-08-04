/* Keyboard support for Material's label-backed mobile header controls. */
(function () {
  "use strict";

  let headerObserver = null;
  const enhancementByLabel = new WeakMap();

  function controlName(controlId, expanded) {
    const noun = controlId === "__drawer" ? "navigation" : "search";
    return `${expanded ? "Close" : "Open"} ${noun}`;
  }

  function syncLabel(controlId, control, label) {
    const expanded = control.checked === true;
    label.setAttribute("aria-expanded", expanded ? "true" : "false");
    label.setAttribute("aria-label", controlName(controlId, expanded));
  }

  function detachEnhancement(label, enhancement) {
    if (!enhancement) return;
    enhancement.control.removeEventListener("change", enhancement.onChange);
    label.removeEventListener("keydown", enhancement.onKeyDown);
  }

  function enhanceLabel(controlId, label) {
    if (!label) return false;

    const control = document.getElementById(controlId);
    if (!control) return false;

    const existing = enhancementByLabel.get(label);
    if (existing && existing.control === control) {
      syncLabel(controlId, control, label);
      return true;
    }

    detachEnhancement(label, existing);

    label.dataset.lacunaKeyboardReady = "true";
    label.setAttribute("role", "button");
    label.setAttribute("tabindex", "0");
    label.setAttribute("aria-controls", controlId);
    if (controlId === "__search") {
      label.setAttribute("aria-haspopup", "dialog");
    } else {
      label.removeAttribute("aria-haspopup");
    }

    const onChange = function () {
      syncLabel(controlId, control, label);
    };

    const onKeyDown = function (event) {
      if (event.key !== "Enter" && event.key !== " ") return;
      event.preventDefault();
      event.stopPropagation();
      // Use the label's native activation path so Material retains ownership of
      // checkbox toggling, search focus, and any future click-side behavior.
      label.click();
    };

    control.addEventListener("change", onChange);
    label.addEventListener("keydown", onKeyDown);
    enhancementByLabel.set(label, { control, onChange, onKeyDown });
    syncLabel(controlId, control, label);
    return true;
  }

  function closeOpenHeaderControl(event) {
    if (event.key !== "Escape") return;

    for (const controlId of ["__search", "__drawer"]) {
      const control = document.getElementById(controlId);
      if (!control || !control.checked) continue;

      const label = document.querySelector(`.md-header__button[for="${controlId}"]`);
      event.preventDefault();
      control.checked = false;
      control.dispatchEvent(new Event("change", { bubbles: true }));
      if (label) label.focus();
      return;
    }
  }

  function enhanceHeaderControls() {
    const drawerReady = enhanceLabel(
      "__drawer",
      document.querySelector('.md-header__button[for="__drawer"]')
    );
    const searchReady = enhanceLabel(
      "__search",
      document.querySelector('.md-header__button[for="__search"]')
    );

    if (drawerReady && searchReady && headerObserver) {
      headerObserver.disconnect();
      headerObserver = null;
    } else if ((!drawerReady || !searchReady) && !headerObserver) {
      headerObserver = new MutationObserver(enhanceHeaderControls);
      headerObserver.observe(document.documentElement, { childList: true, subtree: true });
    }
  }

  document.addEventListener("keydown", closeOpenHeaderControl);

  if (typeof document$ !== "undefined") {
    document$.subscribe(enhanceHeaderControls);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", enhanceHeaderControls);
  } else {
    enhanceHeaderControls();
  }
})();
