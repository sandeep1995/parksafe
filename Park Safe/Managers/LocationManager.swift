//
//  LocationManager.swift
//  Park Safe
//
//  Created by Sandeep Acharya on 03/01/26.
//

import Foundation
import CoreLocation
import Combine
import MapKit

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String = "Locating..."
    @Published var isLoadingAddress: Bool = false
    
    override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestAuthorization()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation() -> CLLocationCoordinate2D? {
        return currentLocation?.coordinate
    }
    
    func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        isLoadingAddress = true
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        guard let request = MKReverseGeocodingRequest(location: location) else {
            isLoadingAddress = false
            completion("Unknown Location")
            return
        }
        
        request.getMapItems { [weak self] (mapItems: [MKMapItem]?, error: (any Error)?) in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoadingAddress = false
                
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    completion("Unknown Location")
                    return
                }
                
                guard let mapItem = mapItems?.first else {
                    completion("Unknown Location")
                    return
                }
                
                var address: String
                
                if let formatted = mapItem.address?.formattedAddress {
                    address = formatted
                } else if let representations = mapItem.addressRepresentations, let first = representations.first {
                    address = first.formattedAddress
                } else if let name = mapItem.name, !name.isEmpty {
                    address = name
                } else if let loc = mapItem.location {
                    let coord = loc.coordinate
                    address = String(format: "%.5f, %.5f", coord.latitude, coord.longitude)
                } else {
                    address = "Unknown Location"
                }
                
                completion(address)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            currentAddress = "Location access denied"
        case .notDetermined:
            requestAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        // Reverse geocode to get address
        reverseGeocodeLocation(location.coordinate) { [weak self] address in
            self?.currentAddress = address
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        currentAddress = "Location unavailable"
    }
}

