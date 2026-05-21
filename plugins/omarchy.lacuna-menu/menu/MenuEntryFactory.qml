import QtQuick

Item {
  id: root

  function entry(values) {
    var source = values || {}
    var kind = source.kind || "item"
    var tone = source.tone || (kind === "header" ? "section" : "nav")
    return {
      kind: kind,
      icon: source.icon || "",
      iconSource: source.iconSource || "",
      label: source.label || "",
      hint: source.hint || "",
      view: source.view || "",
      command: source.command || "",
      action: source.action || "",
      tone: tone,
      priority: source.priority || "normal",
      layout: source.layout || (kind === "header" ? "section" : "row"),
      danger: source.danger === true || tone === "danger",
      group: source.group || "",
      switchVisible: source.switchVisible === true,
      switchChecked: source.switchChecked === true,
      badgeText: source.badgeText || "",
      trailingAction: source.trailingAction || "",
      trailingIcon: source.trailingIcon || "",
      trailingTooltip: source.trailingTooltip || "",
      appId: source.appId || "",
      optionValue: source.optionValue || "",
      optionActionPrefix: source.optionActionPrefix || "",
      options: source.options || [],
      reorderable: source.reorderable === true,
      quickLaunchIndex: source.quickLaunchIndex === undefined ? -1 : source.quickLaunchIndex
    }
  }

  function header(label, tone, group) {
    return entry({
      kind: "header",
      label: label,
      tone: tone || "section",
      group: group || "",
      layout: "section"
    })
  }

  function nav(values) {
    var source = values || {}
    source.kind = "item"
    source.priority = source.priority || "primary"
    source.layout = source.layout || "row"
    return entry(source)
  }

  function featured(values) {
    var source = values || {}
    source.priority = source.priority || "primary"
    source.layout = "featured"
    return nav(source)
  }

  function command(values) {
    return nav(values)
  }

  function action(values) {
    return nav(values)
  }

  function toggle(values) {
    var source = values || {}
    source.switchVisible = true
    return nav(source)
  }

  function option(values) {
    var source = values || {}
    source.layout = "design-style-control"
    source.tone = source.tone || "lacuna"
    return nav(source)
  }

  function grid(group, rows) {
    return {
      kind: "grid",
      group: group || "",
      gridItems: rows || []
    }
  }
}
