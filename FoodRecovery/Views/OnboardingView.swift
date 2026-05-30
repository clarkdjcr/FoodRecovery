//
//  OnboardingView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    var body: some View {
        #if os(iOS)
        TabView(selection: $currentPage) {
            OnboardingWelcomePage(onNext: { currentPage = 1 })
                .tag(0)
            OnboardingHowItWorksPage(onNext: { currentPage = 2 })
                .tag(1)
            OnboardingGetStartedPage(isPresented: $isPresented)
                .tag(2)
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(AppTheme.Colors.background.ignoresSafeArea())
        .interactiveDismissDisabled()
        #else
        VStack(spacing: 0) {
            Group {
                switch currentPage {
                case 0:
                    OnboardingWelcomePage(onNext: { currentPage = 1 })
                case 1:
                    OnboardingHowItWorksPage(onNext: { currentPage = 2 })
                default:
                    OnboardingGetStartedPage(isPresented: $isPresented)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut, value: currentPage)

            if currentPage < 2 {
                HStack {
                    if currentPage > 0 {
                        Button("← Back") { currentPage -= 1 }
                            .buttonStyle(.plain)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    PageIndicator(total: 3, current: currentPage)
                    Spacer()
                    Button("Next →") { currentPage += 1 }
                        .buttonStyle(.plain)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
            }
        }
        .background(AppTheme.Colors.background.ignoresSafeArea())
        #endif
    }
}

// MARK: - Page 1: Welcome

private struct OnboardingWelcomePage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "leaf.arrow.triangle.circlepath")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text("Food Recovery")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Turn surplus food into community impact.\nCoordinate pickups, track deliveries, and reduce waste — all in one place.")
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            #if os(iOS)
            Text("Swipe to learn more →")
                .font(.caption)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.30))
                .padding(.bottom, 48)
            #else
            Button("Learn More →") { onNext() }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.green)
                .fontWeight(.semibold)
                .padding(.bottom, 48)
            #endif
        }
    }
}

// MARK: - Page 2: How It Works

private struct OnboardingHowItWorksPage: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How It Works")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "envelope.badge.fill",
                    color: .blue,
                    title: "AI Email Processing",
                    description: "Forward donation emails and let the app extract food type, quantity, and expiry automatically."
                )
                FeatureRow(
                    icon: "map.fill",
                    color: .green,
                    title: "Optimized Routes",
                    description: "Generate daily pickup and delivery routes that minimize drive time and maximize food rescued."
                )
                FeatureRow(
                    icon: "chart.bar.fill",
                    color: .orange,
                    title: "Impact Tracking",
                    description: "Monitor meals provided, CO₂ diverted, and food bank capacity — and export reports for grants."
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            #if os(iOS)
            Text("Swipe to get started →")
                .font(.caption)
                .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.30))
                .padding(.bottom, 48)
            #else
            Button("Get Started →") { onNext() }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundColor(.green)
                .fontWeight(.semibold)
                .padding(.bottom, 48)
            #endif
        }
    }
}

// MARK: - Page 3: Get Started

private struct OnboardingGetStartedPage: View {
    @Binding var isPresented: Bool
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            VStack(spacing: 12) {
                Text("You're Ready!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Start by setting up your regional operation,\nthen add food banks and food providers.")
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                OnboardingStep(number: "1", text: "Regional Setup → create your operation")
                OnboardingStep(number: "2", text: "Food Banks → register partner organizations")
                OnboardingStep(number: "3", text: "Food Providers → add donation sources")
                OnboardingStep(number: "4", text: "Settings → add your OpenAI key for smart email processing")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                onboardingCompleted = true
                isPresented = false
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Helper Views

private struct PageIndicator: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.green : Color.gray.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

private struct OnboardingStep: View {
    let number: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
