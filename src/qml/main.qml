/*
 * SPDX-FileCopyrightText: 2020 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.12
import Qt.labs.platform 1.0 as Platform
import QtQml 2.12

import org.kde.kirigami 2.11 as Kirigami
import org.kde.haruna 1.0

import mpv 1.0
import "Menus"
import "Menus/Global"
import "Settings"

Kirigami.ApplicationWindow {
    id: window

    property var configure: actionsManager.action("configure")
    property int previousVisibility: Window.Windowed
    property var appActions: actions.list

    visible: true
    title: mpv.mediaTitle || i18n("Haruna")
    width: 1200
    minimumWidth: 700
    height: 720
    minimumHeight: 450
    color: Kirigami.Theme.backgroundColor

    onVisibilityChanged: {
        if (PlaybackSettings.pauseWhileMinimized) {
            if (visibility === Window.Minimized) {
                mpv.pause = true
            }
            if (previousVisibility === Window.Minimized
                    && visibility === Window.Windowed | Window.Maximized | Window.FullScreen) {
                mpv.pause = false
            }
        }

        previousVisibility = visibility
    }

    header: Header { id: header }

    menuBar: Loader {
        id: menuBarLoader

        property bool showGlobalMenu: Kirigami.Settings.hasPlatformMenuBar && !Kirigami.Settings.isMobile

        visible: !window.isFullScreen() && GeneralSettings.showMenuBar && !Kirigami.Settings.hasPlatformMenuBar

        sourceComponent: menuBarComponent
    }

    Component {
        id: menuBarComponent

        MenuBar {
            id: menuBar
            hoverEnabled: true
            background: Rectangle {
                color: Kirigami.Theme.backgroundColor
            }
            Kirigami.Theme.colorSet: Kirigami.Theme.Header

            FileMenu {}
            ViewMenu {}
            PlaybackMenu {}
            VideoMenu {}
            SubtitlesMenu {}
            AudioMenu {}
            SettingsMenu {}
            HelpMenu {}
        }
    }

    Component {
        id: hamburgerMenuComponent

        HamburgerMenu { id: hamburgerMenu }
    }

    Platform.MenuBar {
        GlobalFileMenu {}
        GlobalViewMenu {}
        GlobalPlaybackMenu {}
        GlobalVideoMenu {}
        GlobalSubtitlesMenu {}
        GlobalAudioMenu {}
        GlobalSettingsMenu {}
        GlobalHelpMenu {}
    }

    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }

    Loader {
        id: settingsLoader

        active: false
        sourceComponent: SettingsWindow {}
    }

    Actions { id: actions }

    MpvVideo {
        id: mpv

        Osd { id: osd }
    }

    PlayList { id: playList }

    Footer { id: footer }

    Instantiator {
        model: proxyCustomCommandsModel
        delegate: Action {
            property var qaction: actionsManager.action(model.commandId)
            text: qaction.text
            shortcut: qaction.shortcutName
            onTriggered: {
                mpv.userCommand(model.command)
                osd.message(mpv.command(["expand-text", model.osdMessage]))
            }
        }
    }

    Connections {
        target: app
        onQmlApplicationMouseLeave: {
            if (PlaylistSettings.canToggleWithMouse && window.isFullScreen()) {
                playList.state = "hidden"
            }
        }
    }

    Platform.FileDialog {
        id: fileDialog

        property url location: GeneralSettings.fileDialogLocation
                               ? app.pathToUrl(GeneralSettings.fileDialogLocation)
                               : app.pathToUrl(GeneralSettings.fileDialogLastLocation)

        folder: location
        title: i18n("Select file")
        fileMode: Platform.FileDialog.OpenFile

        onAccepted: {
            openFile(fileDialog.file.toString(), true, PlaylistSettings.loadSiblings, true)
            // the timer scrolls the playlist to the playing file
            // once the table view rows are loaded
            playList.scrollPositionTimer.start()
            mpv.focus = true

            GeneralSettings.fileDialogLastLocation = app.parentUrl(fileDialog.file)
            GeneralSettings.save()
        }
        onRejected: mpv.focus = true
    }

    Popup {
        id: openUrlPopup
        x: 10
        y: 10

        onOpened: {
            openUrlTextField.forceActiveFocus(Qt.MouseFocusReason)
            openUrlTextField.selectAll()
        }

        RowLayout {
            anchors.fill: parent

            Label {
                text: i18n("<a href=\"https://youtube-dl.org\">Youtube-dl</a> was not found.")
                visible: !app.hasYoutubeDl()
                onLinkActivated: Qt.openUrlExternally(link)
            }

            TextField {
                id: openUrlTextField

                visible: app.hasYoutubeDl()
                Layout.preferredWidth: 400
                Layout.fillWidth: true
                Component.onCompleted: text = GeneralSettings.lastUrl

                Keys.onPressed: {
                    if (event.key === Qt.Key_Enter
                            || event.key === Qt.Key_Return) {
                        openUrlButton.clicked()
                    }
                    if (event.key === Qt.Key_Escape) {
                        openUrlPopup.close()
                    }
                }
            }
            Button {
                id: openUrlButton

                visible: app.hasYoutubeDl()
                text: i18n("Open")

                onClicked: {
                    openFile(openUrlTextField.text, true, false, true)
                    GeneralSettings.lastUrl = openUrlTextField.text
                    // in case the url is a playList, it opens the first video
                    GeneralSettings.lastPlaylistIndex = 0
                    openUrlPopup.close()
                    openUrlTextField.clear()
                }
            }
        }
    }

    Component.onCompleted: app.activateColorScheme(GeneralSettings.colorScheme)

    function openFile(path, startPlayback, loadSiblings, addToRecentFiles = false) {

        if (addToRecentFiles) {
            recentFilesModel.addUrl(path)
        }

        if (app.isYoutubePlaylist(path)) {
            mpv.getYouTubePlaylist(path);
            playList.isYouTubePlaylist = true
        } else {
            playList.isYouTubePlaylist = false
        }

        mpv.playlistModel.clear()
        mpv.pause = !startPlayback
        if (loadSiblings) {
            // get video files from same folder as the opened file
            mpv.playlistModel.getVideos(path)
        } else {
            mpv.playlistModel.appendVideo(path)
        }

        mpv.loadFile(path)
    }

    function isFullScreen() {
        return window.visibility === Window.FullScreen
    }

    function toggleFullScreen() {
        if (!isFullScreen()) {
            window.showFullScreen()
        } else {
            exitFullscreen()
        }
        playList.scrollPositionTimer.start()
    }

    function exitFullscreen() {
        if (window.previousVisibility === Window.Maximized) {
            window.show()
            window.showMaximized()
        } else {
            window.showNormal()
        }
    }
}
