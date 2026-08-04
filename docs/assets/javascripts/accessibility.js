/* Keyboard support for Material's label-backed mobile header controls. */
(function () {
  "use strict";

  let headerObserver = null;

  function enhanceLabel(controlId, label) {
    if (!label) return false;
    if (label.dataset.lacunaKeyboardReady === "true") return true;

    const control = document.getElementById(controlId);
    if (!control) return false;

    label.dataset.lacunaKeyboardReady = "true";
    label.setAttribute("role", "button");
    label.setAttribute("tabindex", "0");
    label.setAttribute("aria-controls", controlId);
    label.setAttribute("aria-expanded", control.checked ? "true" : "false");

    if (!label.hasAttribute("aria-label")) {
      label.setAttribute(
        "aria-label",
        controlId === "__drawer" ? "Open navigation" : "Open search"
      );
    }

    control.addEventListener("change", function () {
      label.setAttribute("aria-expanded", control.checked ? "true" : "false");
      label.setAttribute(
        "aria-label",
        controlId === "__drawer"
          ? (control.checked ? "Close navigation" : "Open navigation")
          : (control.checked ? "Close search" : "Open search")
      );
    });

    label.addEventListener("keydown", function (event) {
      if (event.key !== "Enter" && event.key !== " ") return;
      event.preventDefault();
      event.stopPropagation();
      control.checked = !control.checked;
      control.dispatchEvent(new Event("change", { bubbles: true }));
    });

    return true;
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

  if (typeof document$ !== "undefined") {
    document$.subscribe(enhanceHeaderControls);
  } else if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", enhanceHeaderControls);
  } else {
    enhanceHeaderControls();
  }
})();
