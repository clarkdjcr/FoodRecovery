// AppTips.swift
// TipKit tips for key in-app actions. Displayed once per install.

import TipKit

struct GenerateScheduleTip: Tip {
    var title: Text { Text("Generate Today's Routes") }
    var message: Text? { Text("Tap to build optimized pickup and delivery routes for the day.") }
    var image: Image? { Image(systemName: "calendar.badge.plus") }
}

struct RoutePreviewTip: Tip {
    var title: Text { Text("Preview Before Dispatching") }
    var message: Text? { Text("Long-press any route to see all stops on a map before sending a driver.") }
    var image: Image? { Image(systemName: "map") }
}

struct DriverNotesTip: Tip {
    var title: Text { Text("Leave Stop Instructions") }
    var message: Text? { Text("Tap here to add gate codes or special delivery notes for this stop.") }
    var image: Image? { Image(systemName: "note.text") }
}

struct BulkSMSTip: Tip {
    var title: Text { Text("Notify Everyone at Once") }
    var message: Text? { Text("Send a single message to all food providers and banks when a schedule changes.") }
    var image: Image? { Image(systemName: "message.badge.filled.fill") }
}
