/*
 * SPDX-FileCopyrightText: 2022 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt.labs.platform 1.1 as Labs

Labs.Menu {
    id: root

    title: i18n("&Settings")

    Labs.MenuItem {
        icon.name: actions.configureAction.icon.name
        text: actions.configureAction.text
        onTriggered: actions.configureAction.trigger()
    }
    Labs.MenuItem {
        icon.name: actions.configureShortcutsAction.icon.name
        text: actions.configureShortcutsAction.text
        onTriggered: actions.configureShortcutsAction.trigger()
    }
}
