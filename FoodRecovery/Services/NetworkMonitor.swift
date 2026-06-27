// NetworkMonitor.swift
// Watches NWPathMonitor and publishes connectivity state app-wide.

import Foundation
import Network

final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.foodrecovery.network", qos: .utility)

    @Published private(set) var isConnected = true
    @Published private(set) var isExpensive = false  // cellular / hotspot

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
