// AddContactDialog.qml — Modal dialog for creating a new contact
// --------------------------------------------------------------
// Expects a `viewModel` property (ContactListViewModel).
//
// Behaviour:
//   • Name field is required; OK button is disabled until it is non-empty.
//   • Email and phone are optional.
//   • On OK: calls viewModel.addContact(name, email, phone) then closes.
//   • On Cancel / backdrop tap: discards input and closes.

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root

    // Injected from Main.qml
    required property var viewModel

    // ------------------------------------------------------------------ //
    // Dialog chrome
    // ------------------------------------------------------------------ //
    title:       "New Contact"
    modal:       true
    anchors.centerIn: parent

    width:       Math.min(parent.width - 32, 360)
    // Height adapts to content

    Material.theme: Material.Dark

    // ------------------------------------------------------------------ //
    // Clear the form fields whenever the dialog opens
    // ------------------------------------------------------------------ //
    onOpened: {
        nameField.text  = "";
        emailField.text = "";
        phoneField.text = "";
        nameField.forceActiveFocus();
    }

    // ------------------------------------------------------------------ //
    // Input form
    // ------------------------------------------------------------------ //
    contentItem: ColumnLayout {
        spacing: 8
        width:   root.availableWidth

        // ── Name (required) ───────────────────────────────────────────
        TextField {
            id:               nameField
            Layout.fillWidth: true
            placeholderText:  "Full name *"
            inputMethodHints: Qt.ImhNoPredictiveText
            // Press Return to advance to the email field
            Keys.onReturnPressed: emailField.forceActiveFocus()
        }

        Label {
            visible:        nameField.text.trim().length === 0
            text:           "Name is required"
            font.pixelSize: 11
            color:          Material.color(Material.Red)
            leftPadding:    4
        }

        // ── Email (optional) ──────────────────────────────────────────
        TextField {
            id:               emailField
            Layout.fillWidth: true
            placeholderText:  "Email address"
            inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoPredictiveText
            Keys.onReturnPressed: phoneField.forceActiveFocus()
        }

        // ── Phone (optional) ──────────────────────────────────────────
        TextField {
            id:               phoneField
            Layout.fillWidth: true
            placeholderText:  "Phone number"
            inputMethodHints: Qt.ImhDialableCharactersOnly
            Keys.onReturnPressed: {
                if (okButton.enabled)
                    root._commitAndClose();
            }
        }
    }

    // ------------------------------------------------------------------ //
    // Button row
    // ------------------------------------------------------------------ //
    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Cancel

        Button {
            id:                     okButton
            text:                   "Add Contact"
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            enabled:                nameField.text.trim().length > 0
            highlighted:            true
        }
    }

    // ------------------------------------------------------------------ //
    // Signal handling
    // ------------------------------------------------------------------ //
    onAccepted: root._commitAndClose()
    onRejected: root.close()

    // ------------------------------------------------------------------ //
    // Private helper
    // ------------------------------------------------------------------ //
    function _commitAndClose() {
        const name  = nameField.text.trim();
        const email = emailField.text.trim();
        const phone = phoneField.text.trim();

        if (name.length === 0)
            return;   // guard — should not happen (button is disabled)

        root.viewModel.addContact(name, email, phone);
        root.close();
    }
}
