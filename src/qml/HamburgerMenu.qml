/*
 * SPDX-FileCopyrightText: 2022 Kartikey Subramanium <kartikey@tutanota.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.kde.kirigami 2.11 as Kirigami
import org.kde.haruna 1.0
import "Menus"

ToolButton {
    id: root

    property alias menu: menu
    property int position: HamburgerMenu.Position.Header

    enum Position {
        Header = 0,
        Footer
    }

    icon.name: "application-menu"
    focusPolicy: Qt.NoFocus

    onReleased: {
        menu.visible = !menu.visible
    }

    Menu {
        id: menu

        y: root.position === HamburgerMenu.Position.Header
           ? parent.height + Kirigami.Units.smallSpacing
           : -height - Kirigami.Units.smallSpacing
        closePolicy: Popup.CloseOnReleaseOutsideParent

        MenuItem {
            action: appActions.openFileAction
            visible: root.position === HamburgerMenu.Position.Footer
        }
        MenuItem {
            action: appActions.openUrlAction
            visible: root.position === HamburgerMenu.Position.Footer
        }

        Menu {
            title: i18nc("@action:inmenu", "Recent Files")

            Repeater {
                model: recentFilesModel
                delegate: MenuItem {
                    text: model.name
                    onClicked: window.openFile(model.path)
                }
            }
        }

        MenuSeparator {}

        MenuItem { action: appActions.toggleFullscreenAction }
        MenuItem { action: appActions.toggleDeinterlacingAction }
        MenuItem { action: appActions.screenshotAction }

        MenuSeparator {}

        MenuItem {
            action: appActions.configureAction
            visible: root.position === HamburgerMenu.Position.Footer
        }
        MenuItem { action: appActions.configureShortcutsAction }
        MenuItem { action: appActions.aboutHarunaAction }

        MenuSeparator {}

        Menu {
            title: i18nc("@action:inmenu", "&More")

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
}
