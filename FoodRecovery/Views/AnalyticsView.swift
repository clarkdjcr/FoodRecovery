// AnalyticsView.swift
// Activity heat map + capacity forecasts for the selected operation.

import Charts
import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    @Query private var operations: [RegionalOperation]

    private var operation: RegionalOperation? { operations.first(where: { $0.isActive }) ?? operations.first }

    var body: some View {
        if let operation {
            ScrollView {
                VStack(spacing: 20) {
                    ActivityHeatMapCard(operation: operation)
                    CapacityForecastCard(operation: operation)
                    PickupVolumeChartCard(operation: operation)
                }
                .padding()
            }
            .navigationTitle("Analytics")
        } else {
            ContentUnavailableView(
                "No Operation",
                systemImage: "chart.xyaxis.line",
                description: Text("Set up a regional operation first to see analytics.")
            )
            .navigationTitle("Analytics")
        }
    }
}

// MARK: - Activity Heat Map

struct ActivityHeatMapCard: View {
    let operation: RegionalOperation

    private struct HotSpot: Identifiable {
        let id: UUID
        let coordinate: CLLocationCoordinate2D
        let count: Int
        let isPickup: Bool
        var radius: CLLocationDistance { max(300, 500 * sqrt(Double(count))) }
    }

    private var hotSpots: [HotSpot] {
        var spots: [HotSpot] = []

        let pickupsByProvider = Dictionary(
            grouping: operation.pickupRoutes.flatMap { $0.pickups }.filter { $0.foodProvider != nil },
            by: { $0.foodProvider!.id }
        )
        for provider in operation.foodProviders {
            guard let lat = provider.latitude, let lon = provider.longitude else { continue }
            let count = pickupsByProvider[provider.id]?.count ?? 0
            guard count > 0 else { continue }
            spots.append(HotSpot(
                id: provider.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                count: count, isPickup: true
            ))
        }

        let deliveriesByBank = Dictionary(
            grouping: operation.pickupRoutes.flatMap { $0.deliveries }.filter { $0.foodBank != nil },
            by: { $0.foodBank!.id }
        )
        for bank in operation.foodBanks {
            guard let lat = bank.latitude, let lon = bank.longitude else { continue }
            let count = deliveriesByBank[bank.id]?.count ?? 0
            guard count > 0 else { continue }
            spots.append(HotSpot(
                id: bank.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                count: count, isPickup: false
            ))
        }

        return spots
    }

    private var mapCenter: MapCameraPosition {
        let center = CLLocationCoordinate2D(
            latitude: operation.regionCenterLatitude,
            longitude: operation.regionCenterLongitude
        )
        let span = operation.radiusMiles * 1609.34 * 2.2
        return .region(MKCoordinateRegion(center: center, latitudinalMeters: span, longitudinalMeters: span))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.orange)
                Text("Activity Heat Map")
                    .font(.headline)
                Spacer()
                Text("\(hotSpots.count) locations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if hotSpots.isEmpty {
                ContentUnavailableView("No Activity Yet", systemImage: "mappin.slash")
                    .frame(height: 260)
            } else {
                Map(initialPosition: mapCenter) {
                    ForEach(hotSpots) { spot in
                        MapCircle(center: spot.coordinate, radius: spot.radius)
                            .foregroundStyle(
                                (spot.isPickup ? Color.orange : Color.green).opacity(0.25)
                            )
                            .stroke(
                                spot.isPickup ? Color.orange : Color.green,
                                lineWidth: 1.5
                            )
                        Annotation(spot.isPickup ? "P" : "D", coordinate: spot.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(spot.isPickup ? Color.orange : Color.green)
                                    .frame(width: 22, height: 22)
                                Text("\(spot.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(height: 260)
                .cornerRadius(12)

                HStack(spacing: 16) {
                    Label("Pickup locations", systemImage: "circle.fill").foregroundColor(.orange)
                    Label("Delivery locations", systemImage: "circle.fill").foregroundColor(.green)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Capacity Forecast

struct CapacityForecastCard: View {
    let operation: RegionalOperation

    fileprivate struct BankForecast: Identifiable {
        let id: UUID
        let name: String
        let currentPct: Double
        let avgDailyLbs: Double
        let daysToFull: Int?
        let statusColor: Color
        let statusLabel: String
    }

    private var forecasts: [BankForecast] {
        let cutoff = Date().addingTimeInterval(-14 * 86400)
        return operation.foodBanks.map { bank in
            let recent = bank.deliveries.filter {
                $0.status == .completed && $0.scheduledTime >= cutoff
            }
            let total = recent.reduce(0.0) { $0 + $1.totalQuantity }
            let avgDaily = total / 14.0
            let remaining = max(0.0, Double(bank.capacity - bank.dailyUsage))
            let daysToFull: Int? = avgDaily > 0.5 ? Int(ceil(remaining / avgDaily)) : nil
            let pct = bank.utilizationPercentage

            let (color, label): (Color, String) = {
                switch pct {
                case 90...: return (.red, "Critical")
                case 75...: return (.orange, "High")
                case 50...: return (.yellow, "Moderate")
                default: return (.green, "Healthy")
                }
            }()

            return BankForecast(
                id: bank.id,
                name: bank.name,
                currentPct: pct,
                avgDailyLbs: avgDaily,
                daysToFull: daysToFull,
                statusColor: color,
                statusLabel: label
            )
        }
        .sorted { $0.currentPct > $1.currentPct }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.purple)
                Text("Capacity Forecast")
                    .font(.headline)
                Spacer()
                Text("14-day trend")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if forecasts.isEmpty {
                Text("No food banks configured.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(forecasts) { fc in
                    ForecastRow(forecast: fc)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.06))
        .cornerRadius(12)
    }
}

private struct ForecastRow: View {
    let forecast: CapacityForecastCard.BankForecast

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(forecast.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(forecast.statusLabel)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(forecast.statusColor.opacity(0.15))
                    .foregroundColor(forecast.statusColor)
                    .cornerRadius(6)
            }

            ProgressView(value: min(forecast.currentPct / 100, 1.0))
                .tint(forecast.statusColor)

            HStack {
                let pct = String(format: "%.0f", forecast.currentPct)
                Text("\(pct)% utilized")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let days = forecast.daysToFull {
                    Group {
                        if days <= 3 {
                            Label("Full in \(days)d", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        } else {
                            Text("~\(days) days to capacity")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                } else {
                    Text("Stable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(8)
    }
}

// MARK: - Pickup Volume Chart

private struct PickupVolumeChartCard: View {
    let operation: RegionalOperation

    private struct DayVolume: Identifiable {
        let id = UUID()
        let label: String
        let lbs: Double
        let date: Date
    }

    private var chartData: [DayVolume] {
        let cal = Calendar.current
        return (0..<14).reversed().compactMap { offset -> DayVolume? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let lbs = operation.pickupRoutes
                .filter { cal.isDate($0.date, inSameDayAs: day) && $0.status == .completed }
                .reduce(0.0) { $0 + $1.totalPickupQuantity }
            let label = cal.isDateInToday(day) ? "Today" :
                        cal.isDateInYesterday(day) ? "Yest" :
                        day.formatted(.dateTime.weekday(.abbreviated))
            return DayVolume(label: label, lbs: lbs, date: day)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundColor(.blue)
                Text("14-Day Pickup Volume")
                    .font(.headline)
                Spacer()
                let total = chartData.reduce(0) { $0 + $1.lbs }
                Text(String(format: "%.0f lbs total", total))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Chart(chartData) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("lbs", day.lbs)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}
