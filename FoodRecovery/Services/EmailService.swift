// EmailService.swift
// Real SMTP client over port 465 (SMTPS — TLS from connect).
// Credentials are stored in Keychain via AppConfiguration / KeychainService.

import Foundation
import Network

// MARK: - Public errors

enum EmailServiceError: LocalizedError {
    case missingCredentials
    case connectionFailed(Error)
    case authenticationFailed(String)
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Email credentials not configured. Add Gmail address and App Password in Settings."
        case .connectionFailed(let error):
            return "Could not connect to mail server: \(error.localizedDescription)"
        case .authenticationFailed(let detail):
            return "Mail server rejected credentials: \(detail)"
        case .sendFailed(let detail):
            return "Failed to send email: \(detail)"
        }
    }
}

// MARK: - EmailService

final class EmailService {
    private let host: String
    private let port: UInt16

    init(host: String = AppConfiguration.smtpHost, port: Int = AppConfiguration.smtpPort) {
        self.host = host
        self.port = UInt16(clamping: port)
    }

    // MARK: - Public send methods

    func sendPickupConfirmation(to store: FoodProvider, pickup: Pickup) async throws {
        let subject = "Food Donation Pickup Confirmation – \(pickup.scheduledTime.formatted(date: .abbreviated, time: .shortened))"
        try await send(to: store.contactEmail, subject: subject, body: pickupBody(store: store, pickup: pickup))
    }

    func sendDeliveryConfirmation(to foodBank: FoodBank, delivery: Delivery) async throws {
        let subject = "Food Delivery Confirmation – \(delivery.scheduledTime.formatted(date: .abbreviated, time: .shortened))"
        try await send(to: foodBank.contactEmail, subject: subject, body: deliveryBody(foodBank: foodBank, delivery: delivery))
    }

    func sendRouteConfirmation(to operation: RegionalOperation, route: PickupRoute) async throws {
        let subject = "Daily Route Confirmation – \(route.date.formatted(date: .abbreviated, time: .omitted))"
        try await send(to: operation.contactEmail, subject: subject, body: routeBody(operation: operation, route: route))
    }

    // MARK: - Private dispatch

    private func send(to recipient: String, subject: String, body: String) async throws {
        let username = AppConfiguration.smtpUsername
        let password = AppConfiguration.smtpPassword
        guard !username.isEmpty, !password.isEmpty else {
            throw EmailServiceError.missingCredentials
        }
        let client = SMTPClient(host: host, port: port, username: username, password: password)
        try await client.send(from: username, to: [recipient], subject: subject, body: body)
    }

    // MARK: - Email body builders

    private func pickupBody(store: FoodProvider, pickup: Pickup) -> String {
        let fmt = fullDateFormatter()
        let items = pickup.donations.map { "  • \($0.foodType.rawValue.capitalized): \($0.quantity) lbs" }.joined(separator: "\n")
        return """
        Dear \(store.contactName),

        This email confirms your food donation pickup scheduled for:

          Date & Time: \(fmt.string(from: pickup.scheduledTime))
          Location:    \(store.name)
          Address:     \(store.address)

        Donation Details:
        \(items.isEmpty ? "  (no items listed)" : items)

          Total Quantity: \(pickup.totalQuantity) lbs

        Please ensure the donations are ready at the scheduled time. Contact us immediately if you need to reschedule.

        Thank you for your generous donation!

        Best regards,
        Food Recovery Team
        """
    }

    private func deliveryBody(foodBank: FoodBank, delivery: Delivery) -> String {
        let fmt = fullDateFormatter()
        let items = delivery.donations.map { "  • \($0.foodType.rawValue.capitalized): \($0.quantity) lbs" }.joined(separator: "\n")
        return """
        Dear \(foodBank.contactName),

        This email confirms your food delivery scheduled for:

          Date & Time: \(fmt.string(from: delivery.scheduledTime))
          Location:    \(foodBank.name)
          Address:     \(foodBank.address)

        Delivery Details:
        \(items.isEmpty ? "  (no items listed)" : items)

          Total Quantity: \(delivery.totalQuantity) lbs

        Please ensure someone is available to receive the delivery. Contact us if you need to reschedule.

        Thank you for your partnership in fighting food insecurity!

        Best regards,
        Food Recovery Team
        """
    }

    private func routeBody(operation: RegionalOperation, route: PickupRoute) -> String {
        let fmt = fullDateFormatter()
        let pickups = route.pickups.map {
            "  • \($0.foodProvider?.name ?? $0.restaurant?.name ?? "Unknown Provider") – \(fmt.string(from: $0.scheduledTime))"
        }.joined(separator: "\n")
        let deliveries = route.deliveries.map {
            "  • \($0.foodBank?.name ?? "Unknown Food Bank") – \(fmt.string(from: $0.scheduledTime))"
        }.joined(separator: "\n")
        return """
        Daily Route Confirmation – \(fmt.string(from: route.date))

        Route Summary:
          Start:             \(fmt.string(from: route.startTime))
          End:               \(fmt.string(from: route.endTime))
          Total Distance:    \(String(format: "%.1f", route.totalDistance)) miles
          Estimated Duration:\(String(format: "%.1f", route.estimatedDuration / 3600)) hours

        Pickup Schedule:
        \(pickups.isEmpty ? "  (none)" : pickups)

        Delivery Schedule:
        \(deliveries.isEmpty ? "  (none)" : deliveries)

          Total Pickup:   \(String(format: "%.1f", route.totalPickupQuantity)) lbs
          Total Delivery: \(String(format: "%.1f", route.totalDeliveryQuantity)) lbs

        Please review and confirm all stops.

        Best regards,
        Food Recovery Team
        """
    }

    private func fullDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .short
        return f
    }
}

// MARK: - SMTP client (port 465, TLS on connect)

private actor SMTPClient {
    private let host: String
    private let port: UInt16
    private let username: String
    private let password: String

    private var connection: NWConnection?
    private var buffer = Data()

    init(host: String, port: UInt16, username: String, password: String) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
    }

    func send(from sender: String, to recipients: [String], subject: String, body: String) async throws {
        let conn = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!,
            using: NWParameters(tls: .init(), tcp: .init())
        )
        connection = conn
        defer { conn.cancel() }

        try await connect(conn)

        // Greeting
        try await expectCode(220, in: try await readResponse())

        // EHLO
        try await write("EHLO localhost\r\n")
        try await expectCode(250, in: try await readResponse())

        // AUTH LOGIN
        try await write("AUTH LOGIN\r\n")
        try await expectCode(334, in: try await readResponse())
        try await write(Data(username.utf8).base64EncodedString() + "\r\n")
        try await expectCode(334, in: try await readResponse())
        try await write(Data(password.utf8).base64EncodedString() + "\r\n")
        let authResp = try await readResponse()
        if authResp.code != 235 {
            throw EmailServiceError.authenticationFailed(authResp.lines.first ?? "code \(authResp.code)")
        }

        // Envelope
        try await write("MAIL FROM:<\(sender)>\r\n")
        try await expectCode(250, in: try await readResponse())
        for recipient in recipients {
            try await write("RCPT TO:<\(recipient)>\r\n")
            try await expectCode(250, in: try await readResponse())
        }

        // Message
        try await write("DATA\r\n")
        try await expectCode(354, in: try await readResponse())
        try await write(buildRFC2822(from: sender, to: recipients, subject: subject, body: body))
        try await expectCode(250, in: try await readResponse())

        // Quit
        try await write("QUIT\r\n")
        _ = try? await readResponse()
    }

    // MARK: - Connection

    private func connect(_ conn: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            var finished = false
            conn.stateUpdateHandler = { state in
                guard !finished else { return }
                switch state {
                case .ready:
                    finished = true
                    cont.resume()
                case .failed(let error):
                    finished = true
                    cont.resume(throwing: EmailServiceError.connectionFailed(error))
                case .cancelled:
                    finished = true
                    cont.resume(throwing: EmailServiceError.sendFailed("Connection cancelled"))
                default:
                    break
                }
            }
            conn.start(queue: .global(qos: .utility))
        }
    }

    // MARK: - Protocol helpers

    private struct SMTPResponse {
        let code: Int
        let lines: [String]
    }

    /// Reads a complete SMTP response, including any continuation lines (250-...).
    private func readResponse() async throws -> SMTPResponse {
        var lines: [String] = []
        var code = 0
        while true {
            let raw = try await readLine()
            guard raw.count >= 3, let lineCode = Int(raw.prefix(3)) else {
                throw EmailServiceError.sendFailed("Malformed SMTP response: \(raw)")
            }
            code = lineCode
            let text = raw.count > 4 ? String(raw.dropFirst(4)) : ""
            lines.append(text)
            // A space after the code signals the last line; a dash means more follow.
            let separator: Character = raw.count > 3 ? raw[raw.index(raw.startIndex, offsetBy: 3)] : " "
            if separator == " " { break }
        }
        return SMTPResponse(code: code, lines: lines)
    }

    private func expectCode(_ expected: Int, in response: SMTPResponse) throws {
        guard response.code == expected else {
            throw EmailServiceError.sendFailed("Expected \(expected), got \(response.code): \(response.lines.joined(separator: "; "))")
        }
    }

    private func write(_ text: String) async throws {
        guard let conn = connection else { throw EmailServiceError.sendFailed("No connection") }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            conn.send(content: Data(text.utf8), completion: .contentProcessed { error in
                if let error { cont.resume(throwing: EmailServiceError.connectionFailed(error)) }
                else { cont.resume() }
            })
        }
    }

    private func readLine() async throws -> String {
        while true {
            if let range = buffer.range(of: Data("\r\n".utf8)) {
                let lineData = buffer[buffer.startIndex..<range.lowerBound]
                buffer.removeSubrange(buffer.startIndex...range.upperBound - 1)
                return String(data: lineData, encoding: .utf8) ?? ""
            }
            guard let conn = connection else { throw EmailServiceError.sendFailed("No connection") }
            let chunk: Data = try await withCheckedThrowingContinuation { cont in
                conn.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, isComplete, error in
                    if let error { cont.resume(throwing: EmailServiceError.connectionFailed(error)) }
                    else if let data, !data.isEmpty { cont.resume(returning: data) }
                    else { cont.resume(throwing: EmailServiceError.sendFailed("Connection closed unexpectedly")) }
                }
            }
            buffer.append(chunk)
        }
    }

    // MARK: - RFC 2822 message builder

    private func buildRFC2822(from sender: String, to recipients: [String], subject: String, body: String) -> String {
        var rfc2822DateString: String {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            return f.string(from: Date())
        }
        // Dot-stuffing: lines starting with "." must be escaped to ".."
        let stuffed = body.components(separatedBy: "\n")
            .map { $0.hasPrefix(".") ? "." + $0 : $0 }
            .joined(separator: "\r\n")

        return [
            "Date: \(rfc2822DateString)",
            "From: \(sender)",
            "To: \(recipients.joined(separator: ", "))",
            "Subject: \(subject)",
            "MIME-Version: 1.0",
            "Content-Type: text/plain; charset=UTF-8",
            "Content-Transfer-Encoding: 8bit",
            "",
            stuffed,
            ".",  // end-of-data marker
            ""
        ].joined(separator: "\r\n")
    }
}
