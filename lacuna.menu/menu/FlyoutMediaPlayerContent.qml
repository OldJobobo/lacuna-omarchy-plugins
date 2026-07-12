import QtQuick
import Quickshell.Widgets
import "../components"
import "../services"
import "../settings"

Column {
  id: root

  property var service: null
  property bool compact: false
  property bool open: false
  property bool contentVisible: false
  property color foreground: "#d8dee9"
  property color background: "#101315"
  property color accent: "#88c0d0"
  property color muted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.48)
  property var designTokens: fallbackDesignTokens
  property string bodyFontFamily: "Hack Nerd Font Propo"
  property string query: ""
  property string activeTab: "search"
  property int selectedResultIndex: -1
  property string favoritesFilter: ""
  property string favoritesSort: "recent"
  property string pendingClearKind: ""
  property string feedbackText: ""
  readonly property int resultRowHeight: compact ? 46 : 54
  readonly property int resultPageSize: Math.max(8, Math.ceil(resultScroll.height / (resultRowHeight + resultScroll.spacing)))
  readonly property int initialResultWindow: resultPageSize * 2
  readonly property int queueLength: service && service.queue ? service.queue.length : 0
  readonly property int favoritesRevision: service && service.favoritesRevision !== undefined ? Number(service.favoritesRevision) : 0
  readonly property int favoritesLength: service && service.favoritesLength !== undefined ? Number(service.favoritesLength) : 0
  readonly property string currentSearchFilter: service && service.searchFilter ? String(service.searchFilter) : "all"
  readonly property bool inputIsYoutubeUrl: service && typeof service.isYoutubeUrl === "function" && service.isYoutubeUrl(searchInput.text)
  readonly property int resultCount: service && service.allResults ? service.allResults.length : 0
  readonly property var visibleFavorites: filteredFavorites()

  signal closeRequested()

  function forceSearchFocus() {
    activeTab = "search"
    searchInput.forceActiveFocus()
  }

  function search() {
    activeTab = "search"
    if (!service)
      return

    if (inputIsYoutubeUrl) service.playUrl(searchInput.text)
    else if (String(searchInput.text || "").trim() === "") service.loadDefaultSuggestions()
    else service.search(searchInput.text)
  }

  function clearSearch() {
    searchDebounce.stop()
    searchInput.text = ""
    selectedResultIndex = -1
    ensureDefaultSuggestions()
    searchInput.forceActiveFocus()
  }

  function scheduleSearch() {
    selectedResultIndex = -1
    if (!open || activeTab !== "search" || inputIsYoutubeUrl) {
      searchDebounce.stop()
      return
    }
    var trimmed = String(searchInput.text || "").trim()
    if (trimmed.length >= 2) searchDebounce.restart()
    else searchDebounce.stop()
  }

  function moveResultSelection(delta) {
    var count = service && service.results ? service.results.length : 0
    if (count < 1) {
      selectedResultIndex = -1
      return
    }
    selectedResultIndex = Math.max(0, Math.min(count - 1, selectedResultIndex < 0 ? (delta > 0 ? 0 : count - 1) : selectedResultIndex + delta))
  }

  function activateSelectedResult(addToQueue) {
    if (!service || selectedResultIndex < 0 || !service.results || selectedResultIndex >= service.results.length) {
      search()
      return
    }
    var track = service.results[selectedResultIndex]
    if (addToQueue) {
      service.addToQueue(track)
      showFeedback("Added to queue")
    } else {
      service.playNow(track)
    }
  }

  function filteredFavorites() {
    var source = service && service.favorites ? service.favorites.slice() : []
    var needle = String(favoritesFilter || "").trim().toLowerCase()
    if (needle !== "") {
      source = source.filter(function(track) {
        return [track.title, track.uploader, track.source, track.provider].some(function(value) {
          return String(value || "").toLowerCase().indexOf(needle) !== -1
        })
      })
    }
    if (favoritesSort === "title") {
      source.sort(function(a, b) { return String(a.title || "").localeCompare(String(b.title || "")) })
    } else if (favoritesSort === "provider") {
      source.sort(function(a, b) {
        var providerOrder = String(a.source || a.provider || "").localeCompare(String(b.source || b.provider || ""))
        return providerOrder !== 0 ? providerOrder : String(a.title || "").localeCompare(String(b.title || ""))
      })
    } else {
      source.reverse()
    }
    return source
  }

  function cycleFavoritesSort() {
    favoritesSort = favoritesSort === "recent" ? "title" : favoritesSort === "title" ? "provider" : "recent"
  }

  function favoritesSortLabel() {
    return favoritesSort === "title" ? "Title" : favoritesSort === "provider" ? "Provider" : "Recent"
  }

  function showFeedback(message) {
    feedbackText = String(message || "")
    feedbackTimer.restart()
  }

  function requestClear(kind) {
    if (pendingClearKind === kind) {
      if (service && kind === "favorites") service.clearFavorites()
      else if (service && kind === "queue") service.clearQueue()
      pendingClearKind = ""
      clearConfirmTimer.stop()
      showFeedback(kind === "favorites" ? "Favorites cleared" : "Queue cleared")
      return
    }
    pendingClearKind = kind
    clearConfirmTimer.restart()
  }

  function ensureDefaultSuggestions() {
    if (open && activeTab === "search" && service && String(searchInput.text || "").trim() === "") {
      service.loadDefaultSuggestions()
      defaultSuggestionsTimer.restart()
    }
  }

  function setSearchFilter(value) {
    if (service && typeof service.setSearchFilter === "function")
      service.setSearchFilter(value)
  }

  function durationText(track) {
    return track && track.duration ? String(track.duration) : ""
  }

  function isFavorite(track) {
    var revision = favoritesRevision
    return service && revision >= 0 && service.isFavorite(track)
  }

  function maybeLoadMoreResults() {
    if (!service || !service.canLoadMore || service.searching)
      return

    if (resultScroll.contentY + resultScroll.height >= resultScroll.contentHeight - resultRowHeight * 2)
      service.loadMore(resultPageSize)
  }

  visible: contentVisible
  enabled: open
  opacity: open ? 1 : 0
  anchors.margins: compact ? 10 : 12
  spacing: compact ? 8 : 10
  onOpenChanged: ensureDefaultSuggestions()
  onActiveTabChanged: ensureDefaultSuggestions()
  onServiceChanged: ensureDefaultSuggestions()

  Timer {
    id: searchDebounce
    interval: 320
    repeat: false
    onTriggered: {
      if (root.service && root.open && root.activeTab === "search" && !root.inputIsYoutubeUrl)
        root.service.search(searchInput.text)
    }
  }

  Timer {
    id: clearConfirmTimer
    interval: 2600
    repeat: false
    onTriggered: root.pendingClearKind = ""
  }

  Timer {
    id: feedbackTimer
    interval: 1800
    repeat: false
    onTriggered: root.feedbackText = ""
  }

  Timer {
    id: defaultSuggestionsTimer
    interval: 900
    repeat: false
    onTriggered: {
      if (root.open && root.activeTab === "search" && root.service && String(searchInput.text || "").trim() === "")
        root.service.loadDefaultSuggestions()
    }
  }

  Row {
    width: parent.width
    height: root.compact ? 26 : 30
    spacing: 8

    LacunaText {
      width: parent.width - accountButton.width - headerFavoriteButton.width - closeButton.width - parent.spacing * 3
      anchors.verticalCenter: parent.verticalCenter
      text: "Media"
      color: root.foreground
      fontFamily: "Tektur"
      font.pixelSize: root.compact ? 13 : 15
      font.weight: Font.DemiBold
    }

    LacunaIconButton {
      id: accountButton

      icon: "user-circle"
      accessibleName: root.service && root.service.youtubeLoginEnabled ? "YouTube account connected" : "Connect YouTube account"
      disabled: !root.service
      opacity: disabled ? 0.42 : 1
      foreground: root.foreground
      muted: root.service && root.service.youtubeLoginEnabled ? root.accent : root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 24 : 28
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 13 : 15
      onTriggered: {
        if (root.service && typeof root.service.openYoutubeLogin === "function")
          root.service.openYoutubeLogin()
      }
    }

    LacunaIconButton {
      id: headerFavoriteButton

      icon: root.service && root.service.currentFavorite ? "heart-filled" : "heart"
      accessibleName: root.service && root.service.currentFavorite ? "Remove current track from favorites" : "Favorite current track"
      disabled: !root.service || !root.service.hasTrack
      opacity: disabled ? 0.42 : 1
      foreground: root.foreground
      muted: root.service && root.service.currentFavorite ? root.accent : root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 24 : 28
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 13 : 15
      onTriggered: {
        if (root.service) {
          root.service.toggleFavorite(root.service.currentTrack);
        }
      }
    }

    LacunaIconButton {
      id: closeButton

      icon: "x"
      accessibleName: "Close Media Player"
      foreground: root.foreground
      muted: root.muted
      accent: root.accent
      hoverAccent: root.accent
      buttonSize: root.compact ? 24 : 28
      buttonRadius: root.designTokens.controlRadius
      hoverOpacity: root.designTokens.hoverOpacity
      pressOpacity: root.designTokens.activeOpacity
      iconSize: root.compact ? 13 : 15
      onTriggered: root.closeRequested()
    }

  }

  Item {
    id: body

    width: parent.width
    height: Math.max(0, parent.height - y)

    Row {
      anchors.fill: parent
      spacing: root.compact ? 8 : 10

      SettingsRail {
        id: tabRail

        sections: [{
          id: "search",
          icon: "search",
          label: "Search"
        }, {
          id: "queue",
          icon: "list",
          label: "Queue"
        }, {
          id: "favorites",
          icon: "heart",
          label: "Favorites"
        }]
        currentSection: root.activeTab
        compact: root.compact
        foreground: root.foreground
        muted: root.muted
        accent: root.accent
        background: root.background
        designTokens: root.designTokens
        showLabels: false
        onSectionSelected: function(sectionId) {
          root.activeTab = sectionId
          if (sectionId === "search")
            searchInput.forceActiveFocus()
        }
      }

      Column {
        id: contentColumn

        width: Math.max(0, parent.width - tabRail.width - parent.spacing)
        height: parent.height
        spacing: root.spacing

        LacunaRect {
          visible: root.activeTab === "search"
          height: visible ? (root.compact ? 28 : 32) : 0
          width: parent.width
          radius: root.designTokens.material ? height / 2 : root.designTokens.controlRadius
          color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.07)
          border.width: 1
          border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.14)

          LacunaText {
            visible: searchInput.text === ""
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "Search media or paste YouTube URL"
            color: root.muted
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 10 : 11
          }

          TextInput {
            id: searchInput

            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: searchActionButton.width + 12
            color: root.foreground
            selectedTextColor: root.background
            selectionColor: root.accent
            font.family: root.bodyFontFamily
            font.pixelSize: root.compact ? 10 : 11
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            activeFocusOnTab: true
            Accessible.role: Accessible.EditableText
            Accessible.name: "Search media"
            Accessible.description: "Search configured providers or paste a YouTube URL"
            onTextChanged: {
              root.query = text
              root.scheduleSearch()
            }
            Keys.onDownPressed: function(event) {
              root.moveResultSelection(1)
              event.accepted = true
            }
            Keys.onUpPressed: function(event) {
              root.moveResultSelection(-1)
              event.accepted = true
            }
            Keys.onEscapePressed: function(event) {
              root.closeRequested()
              event.accepted = true
            }
            Keys.onReturnPressed: function(event) {
              root.activateSelectedResult((event.modifiers & Qt.ShiftModifier) !== 0)
              event.accepted = true
            }
            Keys.onEnterPressed: function(event) {
              root.activateSelectedResult((event.modifiers & Qt.ShiftModifier) !== 0)
              event.accepted = true
            }
          }

          LacunaIconButton {
            id: searchActionButton

            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            icon: searchInput.text !== "" && !root.inputIsYoutubeUrl ? "x" : root.inputIsYoutubeUrl ? "player-play" : "search"
            accessibleName: searchInput.text !== "" && !root.inputIsYoutubeUrl ? "Clear search" : root.inputIsYoutubeUrl ? "Play URL" : "Search"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 22 : 24
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 12 : 13
            onTriggered: {
              if (searchInput.text !== "" && !root.inputIsYoutubeUrl) root.clearSearch()
              else root.search()
            }
          }

        }

        Row {
          id: searchFilterRow

          visible: root.activeTab === "search"
          width: parent.width
          height: visible ? (root.compact ? 24 : 28) : 0
          spacing: 6

          LacunaRect {
            width: Math.round((parent.width - parent.spacing) / 2)
            height: parent.height
            radius: root.designTokens.controlRadius
            color: root.currentSearchFilter === "all"
              ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08)
              : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
            border.width: root.currentSearchFilter === "all" ? 1 : 0
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.32)

            LacunaText {
              anchors.centerIn: parent
              text: "All"
              color: root.currentSearchFilter === "all" ? root.foreground : root.muted
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 9 : 10
              font.weight: root.currentSearchFilter === "all" ? Font.DemiBold : Font.Normal
            }

            LacunaStateLayer {
              anchors.fill: parent
              stateColor: root.accent
              hoverOpacity: root.designTokens.hoverOpacity
              pressOpacity: root.designTokens.activeOpacity
              onTriggered: root.setSearchFilter("all")
            }
          }

          LacunaRect {
            width: parent.width - x
            height: parent.height
            radius: root.designTokens.controlRadius
            color: root.currentSearchFilter === "music"
              ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.08)
              : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
            border.width: root.currentSearchFilter === "music" ? 1 : 0
            border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.32)

            LacunaText {
              anchors.centerIn: parent
              text: "Music"
              color: root.currentSearchFilter === "music" ? root.foreground : root.muted
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 9 : 10
              font.weight: root.currentSearchFilter === "music" ? Font.DemiBold : Font.Normal
            }

            LacunaStateLayer {
              anchors.fill: parent
              stateColor: root.accent
              hoverOpacity: root.designTokens.hoverOpacity
              pressOpacity: root.designTokens.activeOpacity
              onTriggered: root.setSearchFilter("music")
            }
          }
        }

        Row {
          visible: (root.activeTab === "queue" && root.queueLength > 0)
            || (root.activeTab === "favorites" && root.favoritesLength > 0)
          width: parent.width
          height: visible ? (root.compact ? 26 : 30) : 0
          spacing: 6

          LacunaText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - clearListButton.width - parent.spacing
            text: root.activeTab === "favorites"
              ? root.visibleFavorites.length + (root.favoritesFilter.trim() !== "" ? " of " + root.favoritesLength : "") + " favorites"
              : root.queueLength + " queued"
            color: root.muted
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 9 : 10
            maximumLineCount: 1
            elide: Text.ElideRight
          }

          LacunaRect {
            id: clearListButton

            visible: root.activeTab === "favorites" ? root.favoritesLength > 0 : root.queueLength > 0
            width: visible ? clearLabel.width + 14 : 0
            height: parent.height
            color: "transparent"
            border.width: root.pendingClearKind === root.activeTab ? 1 : 0
            border.color: root.accent
            activeFocusOnTab: visible
            Accessible.role: Accessible.Button
            Accessible.name: root.pendingClearKind === root.activeTab ? "Confirm clear " + root.activeTab : "Clear " + root.activeTab
            Keys.onReturnPressed: root.requestClear(root.activeTab)
            Keys.onEnterPressed: root.requestClear(root.activeTab)

            LacunaText {
              id: clearLabel
              anchors.centerIn: parent
              text: root.pendingClearKind === root.activeTab ? "Confirm" : "Clear"
              color: root.pendingClearKind === root.activeTab ? root.accent : root.muted
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 9 : 10
            }

            LacunaStateLayer {
              anchors.fill: parent
              stateColor: root.accent
              hoverOpacity: root.designTokens.hoverOpacity
              pressOpacity: root.designTokens.activeOpacity
              onTriggered: root.requestClear(root.activeTab)
            }
          }

        }

        Row {
          id: favoritesTools

          visible: root.activeTab === "favorites" && root.favoritesLength > 0
          width: parent.width
          height: visible ? (root.compact ? 28 : 32) : 0
          spacing: 6

          LacunaRect {
            width: Math.max(0, parent.width - favoritesSortButton.width - parent.spacing)
            height: parent.height
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
            border.width: favoritesFilterInput.activeFocus ? 1 : 0
            border.color: root.accent

            LacunaText {
              visible: favoritesFilterInput.text === ""
              anchors.left: parent.left
              anchors.leftMargin: 8
              anchors.verticalCenter: parent.verticalCenter
              text: "Filter favorites"
              color: root.muted
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 9 : 10
            }

            TextInput {
              id: favoritesFilterInput
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              color: root.foreground
              selectedTextColor: root.background
              selectionColor: root.accent
              font.family: root.bodyFontFamily
              font.pixelSize: root.compact ? 9 : 10
              verticalAlignment: TextInput.AlignVCenter
              activeFocusOnTab: true
              Accessible.role: Accessible.EditableText
              Accessible.name: "Filter favorites"
              onTextChanged: root.favoritesFilter = text
              Keys.onEscapePressed: {
                root.closeRequested()
                event.accepted = true
              }
            }
          }

          LacunaRect {
            id: favoritesSortButton
            width: favoritesSortLabel.width + 18
            height: parent.height
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
            activeFocusOnTab: true
            Accessible.role: Accessible.Button
            Accessible.name: "Sort favorites by " + root.favoritesSortLabel()
            Keys.onReturnPressed: root.cycleFavoritesSort()
            Keys.onEnterPressed: root.cycleFavoritesSort()

            LacunaText {
              id: favoritesSortLabel
              anchors.centerIn: parent
              text: root.favoritesSortLabel()
              color: root.muted
              fontFamily: root.bodyFontFamily
              font.pixelSize: root.compact ? 9 : 10
            }

            LacunaStateLayer {
              anchors.fill: parent
              stateColor: root.accent
              hoverOpacity: root.designTokens.hoverOpacity
              pressOpacity: root.designTokens.activeOpacity
              onTriggered: root.cycleFavoritesSort()
            }
          }
        }

        LacunaText {
          visible: root.service && root.service.errorText !== ""
          width: parent.width
          text: root.service ? root.service.errorText : ""
          color: root.muted
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
          maximumLineCount: 2
          wrapMode: Text.WordWrap
        }

        LacunaText {
          visible: root.feedbackText !== ""
          width: parent.width
          text: root.feedbackText
          color: root.accent
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
          horizontalAlignment: Text.AlignHCenter
        }

        LacunaText {
          visible: root.activeTab === "search" && root.service && root.service.searching
          width: parent.width
          text: "Searching…"
          color: root.muted
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
          horizontalAlignment: Text.AlignHCenter
        }

        LacunaText {
          visible: root.activeTab === "search" && root.service && !root.service.searching
            && String(searchInput.text || "").trim() !== "" && root.resultCount === 0
            && root.service.errorText === ""
          width: parent.width
          text: "No results for “" + String(searchInput.text || "").trim() + "”"
          color: root.muted
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 9 : 10
          horizontalAlignment: Text.AlignHCenter
        }

        LacunaText {
          visible: root.activeTab === "search" && root.service && !root.service.searching && root.resultCount > 0
          width: parent.width
          text: root.resultCount + (root.resultCount === 1 ? " result" : " results")
          color: root.muted
          fontFamily: root.bodyFontFamily
          font.pixelSize: root.compact ? 8 : 9
          horizontalAlignment: Text.AlignRight
        }

        LacunaScrollView {
          id: resultScroll

          visible: root.activeTab === "search"
          width: parent.width
          height: visible ? Math.max(0, parent.height - y) : 0
          spacing: root.compact ? 4 : 5
          showEdgeMasks: true
          edgeMaskColor: root.background
          onContentYChanged: root.maybeLoadMoreResults()
          onHeightChanged: {
            if (root.service) {
              root.service.setVisibleLimit(root.initialResultWindow);
            }
          }

          Connections {
            function onAllResultsChanged() {
              if (root.service)
                root.service.setVisibleLimit(root.initialResultWindow);

            }

            target: root.service
          }

          Repeater {
            model: root.service && root.service.results ? root.service.results : []

            LacunaRect {
              id: resultRow

              required property var modelData
              required property int index
              readonly property bool favorite: root.isFavorite(modelData)
              readonly property color rowAccent: root.accent

              width: parent.width
              height: root.compact ? 46 : 54
              radius: root.designTokens.radius
              color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, rowMouse.reveal * 0.08)
              border.width: root.selectedResultIndex === index ? 1 : root.designTokens.lacuna ? 0 : 1
              border.color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, 0.22)
              clip: true
              activeFocusOnTab: true
              Accessible.role: Accessible.ListItem
              Accessible.name: String(modelData.title || "Untitled media")
              Keys.onReturnPressed: root.service.playNow(modelData)
              Keys.onEnterPressed: root.service.playNow(modelData)
              Keys.onSpacePressed: {
                root.service.addToQueue(modelData)
                root.showFeedback("Added to queue")
              }

              LacunaRect {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 34 : 40
                height: width
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
              }

              Image {
                id: thumb

                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 34 : 40
                height: width
                source: modelData.thumbnail || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: source !== "" && status !== Image.Error
              }

              LacunaRect {
                visible: String(modelData.duration || "") !== ""
                anchors.right: thumb.right
                anchors.rightMargin: 2
                anchors.bottom: thumb.bottom
                anchors.bottomMargin: 2
                width: durationBadgeText.width + 8
                height: root.compact ? 13 : 14
                radius: root.designTokens.controlRadius
                color: Qt.rgba(0, 0, 0, 0.72)

                LacunaText {
                  id: durationBadgeText

                  anchors.centerIn: parent
                  text: modelData.duration || ""
                  color: root.foreground
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 7 : 8
                  maximumLineCount: 1
                }
              }

              LacunaTablerIcon {
                anchors.centerIn: thumb
                visible: thumb.source === "" || thumb.status === Image.Error
                name: "music"
                color: root.accent
                iconSize: root.compact ? 16 : 18
              }

              Column {
                anchors.left: thumb.right
                anchors.leftMargin: 8
                anchors.right: actionRow.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                LacunaText {
                  width: parent.width
                  text: modelData.title || "Untitled video"
                  color: root.foreground
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 9 : 10
                  font.weight: Font.DemiBold
                  maximumLineCount: 1
                  elide: Text.ElideRight
                }

                LacunaText {
                  width: parent.width
                  text: [modelData.source || modelData.provider || "", modelData.uploader || ""].filter(function(v) {
                    return String(v).length > 0;
                  }).join(" / ")
                  color: root.muted
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 8 : 9
                  maximumLineCount: 1
                  elide: Text.ElideRight
                }

              }

              Row {
                id: actionRow

                z: 2
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                LacunaIconButton {
                  icon: resultRow.favorite ? "heart-filled" : "heart"
                  accessibleName: resultRow.favorite ? "Remove from favorites" : "Add to favorites"
                  foreground: root.foreground
                  muted: resultRow.favorite ? root.accent : root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 24 : 26
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 12 : 13
                  onTriggered: {
                    if (root.service) {
                      root.service.toggleFavorite(modelData);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "player-play"
                  accessibleName: "Play now"
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 24 : 26
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 12 : 13
                  onTriggered: {
                    if (root.service) {
                      root.service.playNow(modelData);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "plus"
                  accessibleName: "Add to queue"
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 24 : 26
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 12 : 13
                  onTriggered: {
                    if (root.service) {
                      root.service.addToQueue(modelData);
                      root.showFeedback("Added to queue");
                    }
                  }
                }

              }

              LacunaStateLayer {
                id: rowMouse

                z: 1
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: actionRow.left
                stateColor: root.accent
                hoverOpacity: root.designTokens.hoverOpacity
                pressOpacity: root.designTokens.activeOpacity
                acceptWheel: true
                showFill: false
                onTriggered: {
                  if (root.service) {
                    root.selectedResultIndex = index;
                    root.service.playNow(modelData);
                  }
                }
                onScrolled: function(delta) {
                  resultScroll.scrollBy(delta);
                }
              }

            }

          }

          LacunaText {
            visible: root.service && root.service.canLoadMore
            width: parent.width
            text: "More results below"
            color: root.muted
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 8 : 9
            horizontalAlignment: Text.AlignHCenter
          }

        }

        LacunaScrollView {
          id: queueScroll

          visible: root.activeTab === "queue"
          width: parent.width
          height: visible ? Math.max(0, parent.height - y) : 0
          spacing: root.compact ? 4 : 5
          showEdgeMasks: true
          edgeMaskColor: root.background

          Repeater {
            model: root.service && root.service.queue ? root.service.queue : []

            LacunaRect {
              id: queueRow

              required property var modelData
              required property int index
              readonly property bool favorite: root.isFavorite(modelData)
              readonly property color rowAccent: root.accent
              readonly property bool reorderActionsVisible: queueMouse.containsMouse || activeFocus

              width: parent.width
              height: root.compact ? 50 : 58
              radius: root.designTokens.radius
              color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, queueMouse.reveal * 0.08)
              border.width: root.designTokens.lacuna ? 0 : 1
              border.color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, 0.22)
              clip: true
              activeFocusOnTab: true
              Accessible.role: Accessible.ListItem
              Accessible.name: (index + 1) + ". " + String(modelData.title || "Untitled media")
              Accessible.description: "Press Enter to play, Alt Up or Alt Down to reorder, Delete to remove"
              Keys.onReturnPressed: root.service.playQueued(index)
              Keys.onEnterPressed: root.service.playQueued(index)
              Keys.onDeletePressed: root.service.removeQueued(index)
              Keys.onUpPressed: function(event) {
                if ((event.modifiers & Qt.AltModifier) !== 0) {
                  root.service.moveQueued(index, -1)
                  event.accepted = true
                }
              }
              Keys.onDownPressed: function(event) {
                if ((event.modifiers & Qt.AltModifier) !== 0) {
                  root.service.moveQueued(index, 1)
                  event.accepted = true
                }
              }

              LacunaRect {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 36 : 42
                height: width
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
              }

              Image {
                id: queueThumb

                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 36 : 42
                height: width
                source: modelData.thumbnail || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: source !== "" && status !== Image.Error
              }

              LacunaTablerIcon {
                anchors.centerIn: queueThumb
                visible: queueThumb.source === "" || queueThumb.status === Image.Error
                name: "music"
                color: root.accent
                iconSize: root.compact ? 16 : 18
              }

              Column {
                anchors.left: queueThumb.right
                anchors.leftMargin: 8
                anchors.right: queueActions.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                LacunaText {
                  width: parent.width
                  text: (index + 1) + ". " + (modelData.title || "Untitled video")
                  color: root.foreground
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 9 : 10
                  font.weight: Font.DemiBold
                  maximumLineCount: 1
                  elide: Text.ElideRight
                }

                LacunaText {
                  width: parent.width
                  text: [modelData.source || modelData.provider || "", modelData.uploader || "", modelData.duration || ""].filter(function(v) {
                    return String(v).length > 0;
                  }).join(" / ")
                  color: root.muted
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 8 : 9
                  maximumLineCount: 1
                  elide: Text.ElideRight
                }

              }

              Row {
                id: queueActions

                z: 2
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                LacunaIconButton {
                  icon: queueRow.favorite ? "heart-filled" : "heart"
                  accessibleName: queueRow.favorite ? "Remove from favorites" : "Add to favorites"
                  foreground: root.foreground
                  muted: queueRow.favorite ? root.accent : root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.toggleFavorite(modelData);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "player-play"
                  accessibleName: "Play queued item"
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.playQueued(index);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "arrow-up"
                  visible: queueRow.reorderActionsVisible
                  accessibleName: "Move earlier"
                  enabled: index > 0
                  opacity: enabled ? 1 : 0.36
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.moveQueued(index, -1);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "arrow-down"
                  visible: queueRow.reorderActionsVisible
                  accessibleName: "Move later"
                  enabled: root.service && index < root.service.queue.length - 1
                  opacity: enabled ? 1 : 0.36
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.moveQueued(index, 1);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "x"
                  accessibleName: "Remove from queue"
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.removeQueued(index);
                    }
                  }
                }

              }

              LacunaStateLayer {
                id: queueMouse

                z: 1
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: queueActions.left
                stateColor: root.accent
                hoverOpacity: root.designTokens.hoverOpacity
                pressOpacity: root.designTokens.activeOpacity
                acceptWheel: true
                showFill: false
                onTriggered: {
                  if (root.service) {
                    root.service.playQueued(index);
                  }
                }
                onScrolled: function(delta) {
                  queueScroll.scrollBy(delta);
                }
              }

            }

          }

          Item {
            visible: root.queueLength === 0
            width: parent.width
            height: visible ? Math.max(140, queueScroll.height - 8) : 0

            Column {
              anchors.centerIn: parent
              spacing: 8

              LacunaTablerIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "list"
                color: root.muted
                iconSize: root.compact ? 18 : 20
              }

              LacunaText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Queue is empty"
                color: root.foreground
                fontFamily: root.bodyFontFamily
                font.pixelSize: root.compact ? 10 : 11
              }

              LacunaRect {
                anchors.horizontalCenter: parent.horizontalCenter
                width: queueSearchLabel.width + 16
                height: root.compact ? 26 : 28
                color: "transparent"
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: "Search for media"
                Keys.onReturnPressed: {
                  root.activeTab = "search"
                  searchInput.forceActiveFocus()
                }
                Keys.onEnterPressed: {
                  root.activeTab = "search"
                  searchInput.forceActiveFocus()
                }

                LacunaText {
                  id: queueSearchLabel
                  anchors.centerIn: parent
                  text: "Add media from Search"
                  color: root.accent
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 9 : 10
                }

                LacunaStateLayer {
                  anchors.fill: parent
                  stateColor: root.accent
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  onTriggered: {
                    root.activeTab = "search"
                    searchInput.forceActiveFocus()
                  }
                }
              }
            }
          }

        }

        LacunaScrollView {
          id: favoritesScroll

          visible: root.activeTab === "favorites"
          width: parent.width
          height: visible ? Math.max(0, parent.height - y) : 0
          spacing: root.compact ? 4 : 5
          showEdgeMasks: true
          edgeMaskColor: root.background

          Repeater {
            model: root.visibleFavorites

            LacunaRect {
              required property var modelData
              required property int index
              readonly property color rowAccent: root.accent

              width: parent.width
              height: root.compact ? 50 : 58
              radius: root.designTokens.radius
              color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, favoriteMouse.reveal * 0.08)
              border.width: root.designTokens.lacuna ? 0 : 1
              border.color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, 0.22)
              clip: true
              activeFocusOnTab: true
              Accessible.role: Accessible.ListItem
              Accessible.name: String(modelData.title || "Untitled media")
              Accessible.description: "Press Enter to play, Space to add to queue, or Delete to remove from favorites"
              Keys.onReturnPressed: root.service.playNow(modelData)
              Keys.onEnterPressed: root.service.playNow(modelData)
              Keys.onSpacePressed: {
                root.service.addToQueue(modelData)
                root.showFeedback("Added to queue")
              }
              Keys.onDeletePressed: root.service.toggleFavorite(modelData)

              LacunaRect {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 36 : 42
                height: width
                color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.055)
              }

              Image {
                id: favoriteThumb

                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: root.compact ? 36 : 42
                height: width
                source: modelData.thumbnail || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: source !== "" && status !== Image.Error
              }

              LacunaTablerIcon {
                anchors.centerIn: favoriteThumb
                visible: favoriteThumb.source === "" || favoriteThumb.status === Image.Error
                name: "heart-filled"
                color: root.accent
                iconSize: root.compact ? 16 : 18
              }

              Column {
                anchors.left: favoriteThumb.right
                anchors.leftMargin: 8
                anchors.right: favoriteActions.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                LacunaText {
                  width: parent.width
                  text: modelData.title || "Untitled video"
                  color: root.foreground
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 9 : 10
                  font.weight: Font.DemiBold
                  maximumLineCount: 1
                  elide: Text.ElideRight
                }

                LacunaText {
                  width: parent.width
                  text: [modelData.source || modelData.provider || "", modelData.uploader || "", modelData.duration || ""].filter(function(v) {
                    return String(v).length > 0;
                  }).join(" / ")
                  color: root.muted
                  fontFamily: root.bodyFontFamily
                  font.pixelSize: root.compact ? 8 : 9
                  maximumLineCount: 1
                  elide: Text.ElideRight
                }

              }

              Row {
                id: favoriteActions

                z: 2
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                LacunaIconButton {
                  icon: "player-play"
                  accessibleName: "Play favorite"
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.playNow(modelData);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "plus"
                  accessibleName: "Add favorite to queue"
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.addToQueue(modelData);
                      root.showFeedback("Added to queue");
                    }
                  }
                }

                LacunaIconButton {
                  icon: "heart-filled"
                  accessibleName: "Remove from favorites"
                  foreground: root.foreground
                  muted: root.muted
                  accent: root.accent
                  hoverAccent: root.accent
                  buttonSize: root.compact ? 22 : 24
                  buttonRadius: root.designTokens.controlRadius
                  hoverOpacity: root.designTokens.hoverOpacity
                  pressOpacity: root.designTokens.activeOpacity
                  iconSize: root.compact ? 11 : 12
                  onTriggered: {
                    if (root.service) {
                      root.service.toggleFavorite(modelData);
                    }
                  }
                }

              }

              LacunaStateLayer {
                id: favoriteMouse

                z: 1
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: favoriteActions.left
                stateColor: root.accent
                hoverOpacity: root.designTokens.hoverOpacity
                pressOpacity: root.designTokens.activeOpacity
                acceptWheel: true
                showFill: false
                onTriggered: {
                  if (root.service) {
                    root.service.playNow(modelData);
                  }
                }
                onScrolled: function(delta) {
                  favoritesScroll.scrollBy(delta);
                }
              }

            }

          }

          Item {
            visible: root.favoritesLength === 0
            width: parent.width
            height: visible ? Math.max(140, favoritesScroll.height - 8) : 0

            Column {
              anchors.centerIn: parent
              spacing: 8

              LacunaTablerIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "heart"
                color: root.muted
                iconSize: root.compact ? 18 : 20
              }

              LacunaText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No favorites yet"
                color: root.foreground
                fontFamily: root.bodyFontFamily
                font.pixelSize: root.compact ? 10 : 11
              }

              LacunaText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Favorite media from Search or Queue"
                color: root.muted
                fontFamily: root.bodyFontFamily
                font.pixelSize: root.compact ? 9 : 10
              }
            }
          }

          LacunaText {
            visible: root.favoritesLength > 0 && root.visibleFavorites.length === 0
            width: parent.width
            text: "No favorites match “" + root.favoritesFilter.trim() + "”"
            color: root.muted
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 9 : 10
            horizontalAlignment: Text.AlignHCenter
          }

        }

      }

    }

  }

  DesignTokens {
    id: fallbackDesignTokens

    compact: root.compact
    foreground: root.foreground
    background: root.background
    accent: root.accent
  }

  Behavior on opacity {
    LacunaAnim {
      motion: "fast"
    }

  }

}
