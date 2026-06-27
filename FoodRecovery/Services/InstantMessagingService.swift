//
//  InstantMessagingService.swift
//  FoodRecovery
//
//  Created by Claude Code on 9/12/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(MessageUI)
import MessageUI
#endif

enum MessagingType {
    case sms
    case whatsapp
    case imessage
}

struct DeliveryUpdate {
    let pickupId: String
    let status: String
    let estimatedTime: String?
    let driverName: String?
    let message: String
}

class InstantMessagingService: NSObject, ObservableObject {
    
    static let shared = InstantMessagingService()
    
    @Published var isAvailable = false
    
    override init() {
        super.init()
        checkAvailability()
    }
    
    private func checkAvailability() {
        #if canImport(MessageUI)
        isAvailable = MFMessageComposeViewController.canSendText()
        #else
        isAvailable = false
        #endif
    }
    
    // MARK: - Send Updates
    
    func sendDeliveryUpdate(to phoneNumber: String, update: DeliveryUpdate, type: MessagingType = .sms) {
        guard PhoneValidationService.isValidPhoneNumber(phoneNumber) else {
            print("Invalid phone number: \(phoneNumber)")
            return
        }
        
        let message = formatUpdateMessage(update)
        
        switch type {
        case .sms:
            sendSMS(to: phoneNumber, message: message)
        case .whatsapp:
            sendWhatsApp(to: phoneNumber, message: message)
        case .imessage:
            sendiMessage(to: phoneNumber, message: message)
        }
    }
    
    func sendPickupConfirmation(to phoneNumber: String, pickupDetails: String) {
        guard PhoneValidationService.isValidPhoneNumber(phoneNumber) else {
            print("Invalid phone number: \(phoneNumber)")
            return
        }
        
        let message = "🚚 Pickup Confirmed\n\n\(pickupDetails)\n\nThank you for partnering with us in food recovery!"
        sendSMS(to: phoneNumber, message: message)
    }
    
    func composeBulkSMS(to phoneNumbers: [String], message: String) {
        let valid = phoneNumbers
            .filter { PhoneValidationService.isValidPhoneNumber($0) }
            .map { PhoneValidationService.cleanPhoneNumber($0) }
        guard !valid.isEmpty else { return }

        #if canImport(MessageUI)
        guard MFMessageComposeViewController.canSendText() else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let vc = MFMessageComposeViewController()
            vc.messageComposeDelegate = self
            vc.recipients = valid
            vc.body = message
            #if canImport(UIKit)
            if let topVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController?
                .topmostPresented() {
                topVC.present(vc, animated: true)
            }
            #endif
        }
        #else
        let numbers = valid.joined(separator: ";")
        let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:\(numbers)?&body=\(encoded)") {
            #if canImport(UIKit)
            UIApplication.shared.open(url)
            #endif
        }
        #endif
    }

    func sendDeliveryComplete(to phoneNumber: String, deliveryDetails: String) {
        guard PhoneValidationService.isValidPhoneNumber(phoneNumber) else {
            print("Invalid phone number: \(phoneNumber)")
            return
        }
        
        let message = "✅ Delivery Complete\n\n\(deliveryDetails)\n\nFood has been successfully delivered to the food bank."
        sendSMS(to: phoneNumber, message: message)
    }
    
    // MARK: - Private Methods
    
    private func formatUpdateMessage(_ update: DeliveryUpdate) -> String {
        var message = "🔄 Delivery Update\n\n"
        message += "Status: \(update.status)\n"
        
        if let estimatedTime = update.estimatedTime {
            message += "ETA: \(estimatedTime)\n"
        }
        
        if let driverName = update.driverName {
            message += "Driver: \(driverName)\n"
        }
        
        message += "\n\(update.message)"
        return message
    }
    
    private func sendSMS(to phoneNumber: String, message: String) {
        #if canImport(MessageUI)
        guard MFMessageComposeViewController.canSendText() else {
            print("SMS not available on this device")
            return
        }
        
        DispatchQueue.main.async {
            let messageComposeVC = MFMessageComposeViewController()
            messageComposeVC.messageComposeDelegate = self
            messageComposeVC.recipients = [phoneNumber]
            messageComposeVC.body = message
            
            #if canImport(UIKit)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(messageComposeVC, animated: true)
            }
            #endif
        }
        #else
        // Fallback to SMS URL scheme if MessageUI is not available
        let cleanedNumber = PhoneValidationService.cleanPhoneNumber(phoneNumber)
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let smsURL = URL(string: "sms:\(cleanedNumber)&body=\(encodedMessage)") {
            #if canImport(UIKit)
            UIApplication.shared.open(smsURL)
            #endif
        }
        #endif
    }
    
    private func sendWhatsApp(to phoneNumber: String, message: String) {
        let cleanedNumber = PhoneValidationService.cleanPhoneNumber(phoneNumber)
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let whatsappURL = URL(string: "whatsapp://send?phone=+1\(cleanedNumber)&text=\(encodedMessage)") {
            #if canImport(UIKit)
            if UIApplication.shared.canOpenURL(whatsappURL) {
                UIApplication.shared.open(whatsappURL)
            } else {
                // Fallback to SMS if WhatsApp is not installed
                sendSMS(to: phoneNumber, message: message)
            }
            #else
            // Fallback to SMS if UIKit is not available
            sendSMS(to: phoneNumber, message: message)
            #endif
        }
    }
    
    private func sendiMessage(to phoneNumber: String, message: String) {
        // iMessage uses the same interface as SMS but will automatically use iMessage if available
        sendSMS(to: phoneNumber, message: message)
    }
}

// MARK: - UIViewController helper

#if canImport(UIKit)
private extension UIViewController {
    func topmostPresented() -> UIViewController {
        presentedViewController?.topmostPresented() ?? self
    }
}
#endif

// MARK: - MFMessageComposeViewControllerDelegate

#if canImport(MessageUI)
extension InstantMessagingService: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) {
            switch result {
            case .sent:
                print("Message sent successfully")
            case .cancelled:
                print("Message cancelled")
            case .failed:
                print("Message failed to send")
            @unknown default:
                print("Unknown message result")
            }
        }
    }
}
#endif