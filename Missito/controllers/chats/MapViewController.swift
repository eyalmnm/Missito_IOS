//
//  LocationSelectViewController.swift
//  Missito
//
//  Created by Jenea Vranceanu on 7/12/17.
//  Copyright © 2017 Missito GmbH. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import FontAwesome_swift

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()
    let annotationReuseId = "pin"
    
    private var sendAfterGeocode = false
    private var geoCoderInProgress = false
    private var pointAnnotation: MKPointAnnotation?
    var location: RealmLocation?
    var allowSelection = false
    var onLocationSelected: ((String, Double, Double, Double)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let attributes = [NSFontAttributeName: UIFont.fontAwesome(ofSize: 24)] as Dictionary!
        selectButton.setTitleTextAttributes(attributes, for: .normal)
        selectButton.title = String.fontAwesomeIcon(name: FontAwesome.check)
        
        if !allowSelection {
            navigationItem.rightBarButtonItem = nil
        } else {
            mapView.delegate = self
            mapView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(onMapTapped(recognizer:))))
        }
        
        if let location = location {
            let coordinate = CLLocationCoordinate2D.init(latitude: CLLocationDegrees(location.lat), longitude: CLLocationDegrees(location.lon))
            let region = MKCoordinateRegionMakeWithDistance(coordinate, location.radius, location.radius)
            mapView.setRegion(region, animated: true)
            addAnnotation(coordinate)
        } else {
            if CLLocationManager.locationServicesEnabled() {
                switch(CLLocationManager.authorizationStatus()) {
                case .notDetermined, .restricted, .denied:
                    print("No access to location manager: requestWhenInUseAuthorization()")
                    locationManager.requestWhenInUseAuthorization()
                case .authorizedAlways, .authorizedWhenInUse:
                    locationManager.startUpdatingLocation()
                }
            } else {
                print("Location services are not enabled")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let selectedAnnotation = view.annotation, allowSelection {
            if let lastAnnotation = pointAnnotation, lastAnnotation.isEqual(selectedAnnotation) {
                    return
            }
            if mapView.userLocation.isEqual(selectedAnnotation) {
                removeAnnotation()
            }
            getLocationName(selectedAnnotation.coordinate)
        }
    }
    
    func removeAnnotation() {
        if pointAnnotation != nil {
            mapView.removeAnnotation(pointAnnotation!)
            pointAnnotation = nil
        }
    }
    
    func getLocationName(_ coordinate: CLLocationCoordinate2D, _ completion: ((MKPointAnnotation)->())? = nil) {
        geoCoderInProgress = true
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { placemarksArray, error in
            if let error = error {
                NSLog("Failed to 'reverseGeocodeLocation': %@", error.localizedDescription)
                self.geoCoderInProgress = false
            } else if let array = placemarksArray, let placeMark = array.first {
                var title = ""
                var subtitle = ""
                
                // Country
                if let country = placeMark.country {
                    title += country
                }
                // City
                if let city = placeMark.locality {
                    title += (title.isEmpty ? "" : ", ") + city
                }
                // Location name eg. Apple Inc.
                if let locationName = placeMark.name {
                    subtitle = locationName
                }
                // Street address
                if let street = placeMark.thoroughfare, subtitle != street {
                    subtitle += (subtitle.isEmpty ? "" : ", ") + street
                }
                
                let pointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = coordinate
                pointAnnotation.title = title
                pointAnnotation.subtitle = subtitle
                self.pointAnnotation = pointAnnotation
                self.geoCoderInProgress = false
                if self.sendAfterGeocode {
                    self.sendLocation()
                } else if let completion = completion {
                    completion(pointAnnotation)
                }
                
            }
        }

    }
    
    func addAnnotation(_ coordinate: CLLocationCoordinate2D, zoom: Bool = false) {
        removeAnnotation()
        getLocationName(coordinate) { pointAnnotation in
            self.mapView.addAnnotation(pointAnnotation)
            if zoom {
                self.zoomTo(coordinate: coordinate)
            }
        }
    }
    
    func onMapTapped(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            let point = recognizer.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            addAnnotation(coordinate, zoom: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if let firstView = views.first, let reuseId = firstView.reuseIdentifier, reuseId == self.annotationReuseId {
            mapView.selectAnnotation(firstView.annotation!, animated: false)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationReuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationReuseId)
        }
        pinView?.pinTintColor = UIColor.fountainBlue
        pinView?.canShowCallout = true
        return pinView
    }
    
    func getRadius() -> Double {
        if let point = pointAnnotation?.coordinate {
            let span = mapView.region.span
            
            let loc1 = CLLocation(latitude: point.latitude - span.latitudeDelta * 0.5, longitude: point.longitude)
            let loc2 = CLLocation(latitude: point.latitude + span.latitudeDelta * 0.5, longitude: point.longitude)

            return loc1.distance(from: loc2)
        }
        return 0
    }
    
    private func sendLocation() {
        if geoCoderInProgress {
            sendAfterGeocode = true
            return
        }
        if let completion = onLocationSelected, let point = pointAnnotation {
            let title = [point.title ?? "", point.subtitle ?? ""].joined(separator: ", ").trimmingCharacters(in: .whitespacesAndNewlines)
            completion((title == "," ? "" : title),
                       point.coordinate.latitude,
                       point.coordinate.longitude,
                       getRadius())
            navigationController?.popViewController(animated: true)
        }
    }
    
    
    
    @IBAction func onLocationSelected(_ sender: Any) {
        sendLocation()
    }
    
    func zoomTo(coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.005, 0.005)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, allowSelection {
            locationManager.stopUpdatingLocation()
            zoomTo(coordinate: location.coordinate)
            getLocationName(location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
}
