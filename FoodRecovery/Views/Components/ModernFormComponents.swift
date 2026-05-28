//
//  ModernFormComponents.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Modern Text Field
struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
#if canImport(UIKit)
    var keyboardType: UIKeyboardType = .default
#endif
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(.body)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            TextField(placeholder, text: $text, axis: axis)
                .focused($isFocused)
                .textFieldStyle(.plain)
#if canImport(UIKit)
                .keyboardType(keyboardType)
#endif
                .lineLimit(lineLimit ?? 1...1)
                .foregroundColor(Color(white: 0.1))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

// MARK: - Modern Picker
struct ModernPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    let selection: Binding<SelectionValue>
    let content: Content
    var icon: String? = nil
    
    init(
        _ title: String,
        selection: Binding<SelectionValue>,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.selection = selection
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(.body)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            Picker(title, selection: selection) {
                content
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.93))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Modern Slider
struct ModernSlider: View {
    let title: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let formatter: (Double) -> String
    var icon: String? = nil
    var unit: String = ""
    
    init(
        _ title: String,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        icon: String? = nil,
        unit: String = "",
        formatter: @escaping (Double) -> String = { "\(Int($0))" }
    ) {
        self.title = title
        self.value = value
        self.range = range
        self.step = step
        self.icon = icon
        self.unit = unit
        self.formatter = formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .font(.body)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(formatter(value.wrappedValue))\(unit.isEmpty ? "" : " \(unit)")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.blue.opacity(0.1))
                    )
            }
            
            Slider(value: value, in: range, step: step)
                .tint(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Modern Section Card
struct ModernSectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String
    let content: Content
    
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Modern Button
struct ModernButton: View {
    let title: String
    let action: () -> Void
    var style: ModernButtonStyle = .primary
    var icon: String? = nil
    var isEnabled: Bool = true
    var isLoading: Bool = false
    
    @State private var isPressed = false
    
    enum ModernButtonStyle {
        case primary, secondary, tertiary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AppTheme.Colors.primary
            case .secondary: return Color.gray.opacity(0.2)
            case .tertiary: return .clear
            case .destructive: return AppTheme.Colors.destructive
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return .white
            case .secondary: return .primary
            case .tertiary: return AppTheme.Colors.primary
            }
        }
    }
    
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                HapticFeedback.light()
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(isLoading ? "Processing..." : title)
                    .font(AppTheme.Typography.callout)
                    .transition(.opacity)
            }
            .foregroundColor(isEnabled ? style.foregroundColor : .secondary)
            .padding(.horizontal, AppTheme.Spacing.xxl)
            .padding(.vertical, AppTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .fill(isEnabled ? style.backgroundColor : Color.gray.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .stroke(
                                style == .tertiary ? AppTheme.Colors.primary : .clear,
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(isPressed ? 0.98 : 1.0)
                    .animation(AppTheme.Animation.quick, value: isPressed)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity((isEnabled && !isLoading) ? 1.0 : 0.6)
        .animation(AppTheme.Animation.quick, value: isEnabled)
        .animation(AppTheme.Animation.quick, value: isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Location Display
struct LocationDisplayCard: View {
    let latitude: Double
    let longitude: Double
    let onSelectLocation: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected Location")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Latitude")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(String(format: "%.4f", latitude))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Longitude")
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                            Text(String(format: "%.4f", longitude))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                    }
                }
                
                Spacer()
                
                Button("Select on Map", action: onSelectLocation)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.opacity(0.1))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.93))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(progress: Double, size: CGFloat = 60, lineWidth: CGFloat = 6) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progress > 0.8 ? .red : (progress > 0.6 ? .orange : .green),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Progress Indicator
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int
    let stepTitles: [String]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? .blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .animation(.easeInOut, value: currentStep)
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? .blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .animation(.easeInOut, value: currentStep)
                    }
                }
            }
            
            Text("Step \(currentStep + 1) of \(totalSteps): \(stepTitles[currentStep])")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}