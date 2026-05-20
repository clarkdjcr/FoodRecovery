//
//  TaxBenefitCalculatorView.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import SwiftUI

struct TaxBenefitCalculatorView: View {
    @Binding var dailyWaste: Double
    let operatingDays: Int
    @Binding var avgTicketValue: Double
    @Environment(\.dismiss) private var dismiss
    
    @State private var taxBracket = 0.22 // Default to 22% federal tax bracket
    @State private var stateRate = 0.08 // Default state tax rate
    @State private var wasteCostPercentage = 0.30 // Food cost as % of menu price
    @State private var showingDetails = false
    
    private var calculations: TaxBenefitCalculation {
        TaxBenefitCalculation(
            dailyWaste: dailyWaste,
            operatingDaysPerWeek: operatingDays,
            costBasisPercentage: wasteCostPercentage,
            federalTaxRate: taxBracket,
            stateTaxRate: stateRate
        )
    }
    
    var body: some View {
        // NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Tax Benefit Calculator")
                            .font(AppTheme.Typography.title)
                        
                        Text("Calculate your potential tax savings from food donations")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Input Parameters
                    ModernSectionCard(
                        "Restaurant Parameters",
                        subtitle: "Adjust these values to match your operation",
                        icon: "slider.horizontal.3"
                    ) {
                        VStack(spacing: 20) {
                            ModernSlider(
                                "Daily Food Waste Value",
                                value: $dailyWaste,
                                in: 50...2000,
                                step: 25,
                                icon: "trash.fill",
                                unit: "$",
                                formatter: { String(format: "%.0f", $0) }
                            )
                            
                            ModernSlider(
                                "Food Cost Percentage",
                                value: $wasteCostPercentage,
                                in: 0.15...0.45,
                                step: 0.01,
                                icon: "percent",
                                unit: "%",
                                formatter: { String(format: "%.0f", $0 * 100) }
                            )
                            
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                Text("Operating Days: \\(operatingDays) days/week")
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Tax Rates
                    ModernSectionCard(
                        "Tax Rates",
                        subtitle: "Current federal and state tax brackets",
                        icon: "building.columns.fill"
                    ) {
                        VStack(spacing: 16) {
                            ModernPicker(
                                "Federal Tax Bracket",
                                selection: Binding(
                                    get: { taxBracket },
                                    set: { taxBracket = $0 }
                                ),
                                icon: "flag.fill"
                            ) {
                                Text("12%").tag(0.12)
                                Text("22%").tag(0.22)
                                Text("24%").tag(0.24)
                                Text("32%").tag(0.32)
                                Text("35%").tag(0.35)
                                Text("37%").tag(0.37)
                            }
                            
                            ModernSlider(
                                "State Tax Rate",
                                value: $stateRate,
                                in: 0...0.15,
                                step: 0.01,
                                icon: "map.fill",
                                unit: "%",
                                formatter: { String(format: "%.1f", $0 * 100) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Results
                    VStack(spacing: 16) {
                        // Annual Waste Summary
                        ResultCard(
                            title: "Annual Food Waste",
                            value: "$\\(Int(calculations.annualWasteValue))",
                            subtitle: "\\(Int(calculations.annualWastePounds)) lbs per year",
                            icon: "trash.circle.fill",
                            color: .orange
                        )
                        
                        // Tax Deduction
                        ResultCard(
                            title: "Enhanced Tax Deduction",
                            value: "$\\(Int(calculations.enhancedDeduction))",
                            subtitle: "115% of cost basis (\\(Int(calculations.costBasis)))",
                            icon: "receipt.fill",
                            color: .blue
                        )
                        
                        // Total Savings
                        ResultCard(
                            title: "Annual Tax Savings",
                            value: "$\\(Int(calculations.totalTaxSavings))",
                            subtitle: "Federal: $\\(Int(calculations.federalSavings)), State: $\\(Int(calculations.stateSavings))",
                            icon: "banknote.fill",
                            color: .green
                        )
                        
                        // Waste Disposal Savings
                        ResultCard(
                            title: "Waste Disposal Savings",
                            value: "$\\(Int(calculations.wasteDisposalSavings))",
                            subtitle: "Reduced garbage and hauling fees",
                            icon: "truck.pickup.fill",
                            color: .purple
                        )
                        
                        // Total Annual Benefit
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                Text("Total Annual Benefit")
                                    .font(AppTheme.Typography.headline)
                                Spacer()
                            }
                            
                            Text("$\\(Int(calculations.totalAnnualBenefit))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                            
                            Text("Tax savings + Waste disposal savings")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(.green.opacity(0.3), lineWidth: 2)
                                )
                        )
                    }
                    .padding(.horizontal)
                    
                    // Details Button
                    ModernButton(
                        title: "View Detailed Breakdown",
                        action: { showingDetails = true },
                        style: .secondary,
                        icon: "doc.text.magnifyingglass"
                    )
                    .padding(.horizontal)
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Important Notes")
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            BulletPoint("Tax benefits are based on current IRS regulations")
                            BulletPoint("Enhanced deduction applies to C-Corporations and certain other entities")
                            BulletPoint("Consult your tax advisor for specific guidance")
                            BulletPoint("Donations must be to qualified 501(c)(3) organizations")
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBlue).opacity(0.1))
                    )
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Tax Calculator")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Share Results") {
                        // Share functionality would go here
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingDetails) {
                TaxCalculationDetailsView(calculation: calculations)
            }
        }
    }

struct ResultCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: AppTheme.Shadow.light, radius: 4, x: 0, y: 2)
        )
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
            Text(text)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Tax Calculation Model
struct TaxBenefitCalculation {
    let dailyWaste: Double
    let operatingDaysPerWeek: Int
    let costBasisPercentage: Double
    let federalTaxRate: Double
    let stateTaxRate: Double
    
    var annualWasteValue: Double {
        dailyWaste * Double(operatingDaysPerWeek) * 52
    }
    
    var annualWastePounds: Double {
        annualWasteValue * 0.15 // Rough estimate: $1 of food waste ≈ 0.15 lbs
    }
    
    var costBasis: Double {
        annualWasteValue * costBasisPercentage
    }
    
    var enhancedDeduction: Double {
        costBasis * 1.15 // 115% enhanced deduction
    }
    
    var federalSavings: Double {
        enhancedDeduction * federalTaxRate
    }
    
    var stateSavings: Double {
        enhancedDeduction * stateTaxRate
    }
    
    var totalTaxSavings: Double {
        federalSavings + stateSavings
    }
    
    var wasteDisposalSavings: Double {
        // Estimate $0.15 per pound for disposal costs
        annualWastePounds * 0.15
    }
    
    var totalAnnualBenefit: Double {
        totalTaxSavings + wasteDisposalSavings
    }
    
    var monthlySavings: Double {
        totalAnnualBenefit / 12
    }
    
    var dailySavings: Double {
        totalAnnualBenefit / (Double(operatingDaysPerWeek) * 52)
    }
}

// MARK: - Detailed Breakdown View
struct TaxCalculationDetailsView: View {
    let calculation: TaxBenefitCalculation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Breakdown sections would go here
                    Text("Detailed Tax Calculation Breakdown")
                        .font(AppTheme.Typography.title)
                    
                    // This would contain detailed IRS compliance information,
                    // step-by-step calculations, and relevant tax code references
                    Text("Detailed calculation methodology and IRS compliance information would be displayed here.")
                        .font(.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding()
            }
            .navigationTitle("Calculation Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

#Preview {
    TaxBenefitCalculatorView(
        dailyWaste: .constant(200),
        operatingDays: 6,
        avgTicketValue: .constant(25)
    )
}