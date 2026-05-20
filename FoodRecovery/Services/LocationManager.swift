//
//  LocationManager.swift
//  FoodRecovery
//
//  Created by Donald Clark on 9/11/25.
//

import CoreLocation
import Foundation
import MapKit

@Observable
class LocationManager: NSObject {
    private let locationManager = CLLocationManager()
    
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: Error?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestLocationPermission() {
        #if os(iOS)
        locationManager.requestWhenInUseAuthorization()
        #elseif os(macOS)
        locationManager.requestAlwaysAuthorization()
        #endif
    }
    
    func startTracking() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        #elseif os(macOS)
        guard authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        #endif
        locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
    }
    
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = false
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw LocationError.noRouteFound
        }
        
        return route
    }
    
    func calculateOptimizedRoute(stops: [CLLocationCoordinate2D]) async throws -> [MKRoute] {
        var routes: [MKRoute] = []
        
        for i in 0..<(stops.count - 1) {
            let route = try await calculateRoute(from: stops[i], to: stops[i + 1])
            routes.append(route)
        }
        
        return routes
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        #if os(iOS)
        case .authorizedWhenInUse, .authorizedAlways:
            startTracking()
        #elseif os(macOS)
        case .authorizedAlways:
            startTracking()
        #endif
        case .denied, .restricted:
            locationError = LocationError.permissionDenied
        default:
            break
        }
    }
}

enum LocationError: Error, LocalizedError {
    case permissionDenied
    case noRouteFound
    case locationUnavailable
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .noRouteFound:
            return "No route found between locations"
        case .locationUnavailable:
            return "Current location unavailable"
        }
    }
}