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
  readonly property int resultRowHeight: compact ? 46 : 54
  readonly property int resultPageSize: Math.max(8, Math.ceil(resultScroll.height / (resultRowHeight + resultScroll.spacing)))
  readonly property int initialResultWindow: resultPageSize * 2
  readonly property int queueLength: service && service.queue ? service.queue.length : 0
  readonly property int favoritesRevision: service && service.favoritesRevision !== undefined ? Number(service.favoritesRevision) : 0
  readonly property int favoritesLength: service && service.favoritesLength !== undefined ? Number(service.favoritesLength) : 0
  readonly property string repeatMode: service && service.repeatMode ? String(service.repeatMode) : "none"
  readonly property string currentSearchFilter: service && service.searchFilter ? String(service.searchFilter) : "all"
  readonly property bool inputIsYoutubeUrl: service && typeof service.isYoutubeUrl === "function" && service.isYoutubeUrl(searchInput.text)

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
        if (root.service && typeof root.service.openYoutubeMusicLogin === "function")
          root.service.openYoutubeMusicLogin()
      }
    }

    LacunaIconButton {
      id: headerFavoriteButton

      icon: root.service && root.service.currentFavorite ? "heart-filled" : "heart"
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
            anchors.rightMargin: searchButton.width + 12
            color: root.foreground
            selectedTextColor: root.background
            selectionColor: root.accent
            font.family: root.bodyFontFamily
            font.pixelSize: root.compact ? 10 : 11
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            onTextChanged: root.query = text
            Keys.onReturnPressed: root.search()
            Keys.onEnterPressed: root.search()
          }

          LacunaIconButton {
            id: searchButton

            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            icon: root.inputIsYoutubeUrl ? "player-play" : "search"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 22 : 24
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 12 : 13
            onTriggered: root.search()
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
              ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
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
              ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
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
          id: transportControls

          visible: root.activeTab !== "search"
          width: parent.width
          height: visible ? (root.compact ? 32 : 38) : 0
          spacing: 6

          LacunaIconButton {
            icon: root.service && root.service.playing && !root.service.paused ? "player-pause" : "player-play"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 28 : 32
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 14 : 16
            iconHoverScale: 1.28
            onTriggered: {
              if (root.service) {
                root.service.togglePause();
              }
            }
          }

          LacunaIconButton {
            icon: "player-skip-back"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 28 : 32
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 14 : 16
            iconHoverScale: 1.28
            onTriggered: {
              if (root.service) {
                root.service.previousOrRestart();
              }
            }
          }

          LacunaIconButton {
            icon: "player-stop"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 28 : 32
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 14 : 16
            iconHoverScale: 1.28
            onTriggered: {
              if (root.service) {
                root.service.stop();
              }
            }
          }

          LacunaIconButton {
            icon: "player-skip-forward"
            foreground: root.foreground
            muted: root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 28 : 32
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 14 : 16
            iconHoverScale: 1.28
            onTriggered: {
              if (root.service) {
                root.service.next();
              }
            }
          }

          LacunaIconButton {
            icon: root.repeatMode === "one" ? "repeat-once" : "repeat"
            foreground: root.foreground
            muted: root.repeatMode === "none" ? root.muted : root.accent
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 28 : 32
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 14 : 16
            iconHoverScale: 1.28
            onTriggered: {
              if (root.service) {
                root.service.cycleRepeatMode();
              }
            }
          }

          LacunaIconButton {
            icon: root.service && root.service.currentFavorite ? "heart-filled" : "heart"
            disabled: !root.service || !root.service.hasTrack
            opacity: disabled ? 0.36 : 1
            foreground: root.foreground
            muted: root.service && root.service.currentFavorite ? root.accent : root.muted
            accent: root.accent
            hoverAccent: root.accent
            buttonSize: root.compact ? 28 : 32
            buttonRadius: root.designTokens.controlRadius
            hoverOpacity: root.designTokens.hoverOpacity
            pressOpacity: root.designTokens.activeOpacity
            iconSize: root.compact ? 14 : 16
            iconHoverScale: 1.28
            onTriggered: {
              if (root.service) {
                root.service.toggleFavorite(root.service.currentTrack);
              }
            }
          }

          LacunaText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, parent.width - (root.compact ? 5 * 28 : 5 * 32) - parent.spacing * 5)
            text: root.service && root.service.displayTitle ? root.service.displayTitle : (root.service ? root.service.statusText() : "Service disabled")
            color: root.foreground
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 10 : 11
            maximumLineCount: 1
            elide: Text.ElideRight
          }

        }

        Row {
          visible: root.activeTab === "queue" || root.activeTab === "favorites"
          width: parent.width
          height: visible ? (root.compact ? 26 : 30) : 0
          spacing: 6

          LacunaText {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - clearListButton.width - parent.spacing
            text: root.activeTab === "favorites"
              ? (root.favoritesLength > 0 ? root.favoritesLength + " favorites" : "Favorites are empty")
              : (root.queueLength > 0 ? root.queueLength + " queued" : "Queue is empty")
            color: root.muted
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 9 : 10
            maximumLineCount: 1
            elide: Text.ElideRight
          }

          LacunaIconButton {
            id: clearListButton

            visible: root.activeTab === "favorites" ? root.favoritesLength > 0 : root.queueLength > 0
            icon: "x"
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
              if (root.service && root.activeTab === "favorites") {
                root.service.clearFavorites();
              } else if (root.service) {
                root.service.clearQueue();
              }
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
              readonly property bool favorite: root.isFavorite(modelData)
              readonly property color rowAccent: root.accent

              width: parent.width
              height: root.compact ? 46 : 54
              radius: root.designTokens.radius
              color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, rowMouse.reveal * 0.08)
              border.width: root.designTokens.lacuna ? 0 : 1
              border.color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, 0.22)
              clip: true

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
                id: actionRow

                z: 2
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                LacunaIconButton {
                  icon: resultRow.favorite ? "heart-filled" : "heart"
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

              width: parent.width
              height: root.compact ? 50 : 58
              radius: root.designTokens.radius
              color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, queueMouse.reveal * 0.08)
              border.width: root.designTokens.lacuna ? 0 : 1
              border.color: Qt.rgba(rowAccent.r, rowAccent.g, rowAccent.b, 0.22)
              clip: true

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

          LacunaText {
            visible: root.queueLength === 0
            width: parent.width
            text: "Add media from Search"
            color: root.muted
            fontFamily: root.bodyFontFamily
            font.pixelSize: root.compact ? 9 : 10
            horizontalAlignment: Text.AlignHCenter
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
            model: root.favoritesRevision >= 0 && root.service && root.service.favorites ? root.service.favorites : []

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
                      root.service.playFavorite(index);
                    }
                  }
                }

                LacunaIconButton {
                  icon: "plus"
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
                    }
                  }
                }

                LacunaIconButton {
                  icon: "x"
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
                      root.service.removeFavorite(index);
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
                    root.service.playFavorite(index);
                  }
                }
                onScrolled: function(delta) {
                  favoritesScroll.scrollBy(delta);
                }
              }

            }

          }

          LacunaText {
            visible: root.favoritesLength === 0
            width: parent.width
            text: "Favorite media from Search or Queue"
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
