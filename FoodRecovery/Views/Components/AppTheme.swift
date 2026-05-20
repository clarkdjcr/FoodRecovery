//
//  AppTheme.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - App Theme
struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.gray.opacity(0.6)
        static let accent = Color.green
        static let background = Color(red: 0.95, green: 0.95, blue: 0.97)
        static let cardBackground = Color.white
        static let destructive = Color.red
        static let warning = Color.orange
        static let success = Color.green
        
        // Text colors - explicit colors for better visibility
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
        static let textTertiary = Color.gray.opacity(0.6)
        
        // Status colors
        static let proposed = Color.orange
        static let confirmed = Color.blue
        static let inProgress = Color.yellow
        static let completed = Color.green
        static let cancelled = Color.red
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let callout = Font.callout.weight(.medium)
        static let subheadline = Font.subheadline.weight(.medium)
        static let footnote = Font.footnote
        static let caption = Font.caption
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let round: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let heavy = Color.black.opacity(0.15)
    }
    
    // MARK: - Animations
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bounce = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.6)
    }
}

// MARK: - View Extensions for Theme
extension View {
    func cardStyle() -> some View {
        self
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .shadow(color: AppTheme.Shadow.light, radius: 8, x: 0, y: 4)
    }
    
    func sectionCardStyle() -> some View {
        self
            .padding(AppTheme.Spacing.xl)
            .cardStyle()
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(AppTheme.Typography.callout)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.CornerRadius.md)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(AppTheme.Typography.callout)
            .foregroundColor(AppTheme.Colors.primary)
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.md)
    }
    
    func textFieldStyle() -> some View {
        self
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.md)
    }
    
    func fadeInAnimation(delay: Double = 0) -> some View {
        self
            .opacity(0)
            .animation(
                AppTheme.Animation.smooth.delay(delay),
                value: true
            )
            .onAppear {
                withAnimation(AppTheme.Animation.smooth.delay(delay)) {
                    // Animation will be handled by the opacity change
                }
            }
    }
    
    func slideInFromBottom(delay: Double = 0) -> some View {
        self
            .offset(y: 50)
            .opacity(0)
            .onAppear {
                withAnimation(AppTheme.Animation.spring.delay(delay)) {
                    // Animation will be handled by the offset and opacity changes
                }
            }
    }
    
    func scaleInAnimation(delay: Double = 0) -> some View {
        self
            .scaleEffect(0.8)
            .opacity(0)
            .onAppear {
                withAnimation(AppTheme.Animation.bounce.delay(delay)) {
                    // Animation will be handled by the scale and opacity changes
                }
            }
    }
}

// MARK: - Status Color Helper
extension View {
    func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "proposed", "planned":
            return AppTheme.Colors.proposed
        case "confirmed":
            return AppTheme.Colors.confirmed
        case "in_progress", "inprogress", "active":
            return AppTheme.Colors.inProgress
        case "completed":
            return AppTheme.Colors.completed
        case "cancelled":
            return AppTheme.Colors.cancelled
        default:
            return AppTheme.Colors.secondary
        }
    }
}

// MARK: - Haptic Feedback Helper
struct HapticFeedback {
    static func light() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        #endif
    }
    
    static func medium() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        #endif
    }
    
    static func heavy() {
        #if canImport(UIKit)
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        #endif
    }
    
    static func success() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        #endif
    }
    
    static func warning() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
        #endif
    }
    
    static func error() {
        #if canImport(UIKit)
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
        #endif
    }
}