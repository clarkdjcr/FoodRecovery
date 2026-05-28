//
//  RouteOptimizationService.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/10/25.
//

import CoreLocation
import Foundation

struct RoutePoint {
  let location: CLLocationCoordinate2D
  let name: String
  let type: RoutePointType
  let priority: Int  // Lower number = higher priority
  let timeWindow: TimeWindow?
}

enum RoutePointType {
  case pickup
  case delivery
}

struct TimeWindow {
  let start: Date
  let end: Date
}

struct OptimizedRoute {
  let points: [RoutePoint]
  let totalDistance: Double
  let estimatedDuration: TimeInterval
  let route: [CLLocationCoordinate2D]
}

class RouteOptimizationService {

  func optimizeRoute(
    pickups: [Pickup], deliveries: [Delivery], startLocation: CLLocationCoordinate2D,
    maxDuration: TimeInterval = 4 * 3600
  ) -> OptimizedRoute {
    var routePoints: [RoutePoint] = []

    // Add pickup points
    for pickup in pickups {
      guard let store = pickup.foodProvider else { continue }
      let timeWindow = TimeWindow(
        start: pickup.scheduledTime.addingTimeInterval(-1800),  // 30 min before
        end: pickup.scheduledTime.addingTimeInterval(1800)  // 30 min after
      )

      if let lat = store.latitude, let lon = store.longitude {
        routePoints.append(
          RoutePoint(
            location: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            name: store.name,
            type: .pickup,
            priority: 1,
            timeWindow: timeWindow
          ))
      }
    }

    // Add delivery points
    for delivery in deliveries {
      guard let foodBank = delivery.foodBank else { continue }
      let timeWindow = TimeWindow(
        start: delivery.scheduledTime.addingTimeInterval(-1800),  // 30 min before
        end: delivery.scheduledTime.addingTimeInterval(1800)  // 30 min after
      )

      if let lat = foodBank.latitude, let lon = foodBank.longitude {
        routePoints.append(
          RoutePoint(
            location: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            name: foodBank.name,
            type: .delivery,
            priority: 2,
            timeWindow: timeWindow
          ))
      }
    }

    // Sort by priority and time windows
    routePoints.sort { point1, point2 in
      if point1.priority != point2.priority {
        return point1.priority < point2.priority
      }

      if let window1 = point1.timeWindow, let window2 = point2.timeWindow {
        return window1.start < window2.start
      }

      return false
    }

    // Calculate route using nearest neighbor with time constraints
    let optimizedPoints = nearestNeighborWithTimeConstraints(
      points: routePoints,
      startLocation: startLocation,
      maxDuration: maxDuration
    )

    // Calculate total distance and duration
    let totalDistance = calculateTotalDistance(points: optimizedPoints)
    let estimatedDuration = calculateEstimatedDuration(
      distance: totalDistance, stops: optimizedPoints.count)

    // Generate route coordinates
    let route = generateRouteCoordinates(points: optimizedPoints)

    return OptimizedRoute(
      points: optimizedPoints,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      route: route
    )
  }

  private func nearestNeighborWithTimeConstraints(
    points: [RoutePoint], startLocation: CLLocationCoordinate2D, maxDuration: TimeInterval
  ) -> [RoutePoint] {
    var unvisited = points
    var route: [RoutePoint] = []
    var currentLocation = startLocation
    var currentTime = Date()

    while !unvisited.isEmpty {
      var bestPoint: RoutePoint?
      var bestIndex = -1
      var bestScore = Double.infinity

      for (index, point) in unvisited.enumerated() {
        let distance = calculateDistance(from: currentLocation, to: point.location)
        let travelTime = distance / 30.0 * 3600  // Assume 30 mph average speed
        let arrivalTime = currentTime.addingTimeInterval(travelTime)

        // Check time window constraints
        var timePenalty = 0.0
        if let timeWindow = point.timeWindow {
          if arrivalTime < timeWindow.start {
            timePenalty = timeWindow.start.timeIntervalSince(arrivalTime) / 3600.0  // Hours early
          } else if arrivalTime > timeWindow.end {
            timePenalty = (arrivalTime.timeIntervalSince(timeWindow.end) / 3600.0) * 10  // Heavy penalty for being late
          }
        }

        let score = distance + timePenalty * 10  // Weight time penalties heavily

        if score < bestScore {
          bestScore = score
          bestPoint = point
          bestIndex = index
        }
      }

      guard let point = bestPoint, bestIndex >= 0 else { break }

      route.append(point)
      unvisited.remove(at: bestIndex)
      currentLocation = point.location
      currentTime = currentTime.addingTimeInterval(
        calculateDistance(from: currentLocation, to: point.location) / 30.0 * 3600 + 900)  // Add 15 min for stop
    }

    return route
  }

  private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double
  {
    let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return location1.distance(from: location2) / 1609.34  // Convert meters to miles
  }

  private func calculateTotalDistance(points: [RoutePoint]) -> Double {
    guard points.count > 1 else { return 0 }

    var totalDistance = 0.0
    for i in 0..<points.count - 1 {
      totalDistance += calculateDistance(from: points[i].location, to: points[i + 1].location)
    }
    return totalDistance
  }

  private func calculateEstimatedDuration(distance: Double, stops: Int) -> TimeInterval {
    let drivingTime = distance / 30.0 * 3600  // 30 mph average speed
    let stopTime = Double(stops) * 900  // 15 minutes per stop
    return drivingTime + stopTime
  }

  private func generateRouteCoordinates(points: [RoutePoint]) -> [CLLocationCoordinate2D] {
    return points.map { $0.location }
  }
}
