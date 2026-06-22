import QtQuick; import Quickshell; Window { visible: false; Component.onCompleted: { Quickshell.execDetached(["bash", "-c", "echo 1 > /tmp/cupcake_settings"]); Qt.quit(); } }
