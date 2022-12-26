//
//  ViewController.swift
//  GeoFencing(poc)
//
//  Created by Admin on 26/12/22.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
//    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    private var direction = [String]()
    var directionsArray: [MKDirections] = []
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        
        self.mapView.showsUserLocation = true
        addPointOfInterest()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let nc = segue.destination as? UINavigationController,
              let directionTVC = nc.viewControllers.first as? DirectionTableViewController
        else {
            return
        }
        
        directionTVC.directions = self.direction
    }

    private func addPointOfInterest() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777)
        self.mapView.addAnnotation(annotation)
        
        let region = CLCircularRegion(center: annotation.coordinate, radius: 200, identifier: "region")
        //when a user enter or exit the region then we will notify
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        //overlay
        self.mapView.addOverlay(MKCircle(center: annotation.coordinate, radius: 200))
        
        //monitaring the region
        self.locationManager.startMonitoring(for: region)
    }
    
    @IBAction func showAddAddressView(_ sender: UIBarButtonItem) {
        let alertVC = UIAlertController(title: "Add Address", message: nil, preferredStyle: .alert)
        alertVC.addTextField{ textField in
            
        }
        let okAction = UIAlertAction(title: "OK", style: .default)
        {
            action in
            
            if let textField = alertVC.textFields?.first {
                // reverse geocode the address
                self.reverseGeocode(address: textField.text!) { placemark in
                    
                    let destinationPlacemark = MKPlacemark(coordinate: placemark.location!.coordinate)
                    
                    let startingMapItem = MKMapItem.forCurrentLocation()
                    let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
                    //opening default apple map
                  //  MKMapItem.openMaps(with: [destinationMapItem], launchOptions: nil)
                    
                    //request
                    let directionRequest = MKDirections.Request()
                    directionRequest.transportType = .automobile
                    directionRequest.source = startingMapItem
                    directionRequest.destination = destinationMapItem
                    
                    let direction = MKDirections(request: directionRequest)
                    
                    self.resetMapView(withNew: direction)
                    // calculate method calculate distance between satrt and end
                    direction.calculate { response, error in
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        
                        guard let response = response,
                              let route = response.routes.first else {
                            return
                        }
                        //checking if there is any route or not
                        if !route.steps.isEmpty {
                            //step is direction(turn right or left)
                            for step in route.steps {
                                print(step.instructions)
                                self.direction.append(step.instructions)
                            }
                        }
                        //adding route(blue line)
                        self.mapView.addOverlay(route.polyline, level: .aboveRoads)
                    }
                    
                    
                }
            }
        }
        let cancleAction = UIAlertAction(title: "Cancle", style: .cancel) { action in
            
        }
        
        alertVC.addAction(okAction)
        alertVC.addAction(cancleAction)
        
        self.present(alertVC, animated: true)
    }
    
    
    func reverseGeocode(address: String, complition:@escaping (CLPlacemark) -> Void) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let placemarks = placemarks,
                  let placemark = placemarks.first else {
                return
            }
            complition(placemark)
            
            
        }
    }
    
    func resetMapView(withNew directions: MKDirections) {
            mapView.removeOverlays(mapView.overlays)
            directionsArray.append(directions)
            let _ = directionsArray.map { $0.cancel() }
        }
    
    
    @IBAction func searchNearByButton(_ sender: UIBarButtonItem) {
        let alertVC = UIAlertController(title: "Search near by location", message: nil, preferredStyle: .alert)
        
        alertVC.addTextField{ textField in
            
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            
            if let textField = alertVC.textFields?.first,
               let search = textField.text {
                self.findNearByPointOfInterest(by : search)
            }
        }
        let cancleAction = UIAlertAction(title: "Cancle", style: .cancel) { action in
            
        }
        
        alertVC.addAction(okAction)
        alertVC.addAction(cancleAction)
        
        self.present(alertVC, animated: true)
    }
    
    
        func findNearByPointOfInterest(by searchTerm : String) {
            
            let annotation = self.mapView.annotations
            self.mapView.removeAnnotations(annotation)
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchTerm
            request.region = self.mapView.region
            
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                
                guard let response = response, error == nil else {
                    return
                }
                
                for mapItem in response.mapItems {
                    self.addPlacemarkOnMap(placemark: mapItem.placemark)
                }
            }
        }
    
    private func addPlacemarkOnMap(placemark: CLPlacemark) {
        let coordinate = placemark.location?.coordinate
        let annotation = MKPointAnnotation()
        annotation.title = placemark.name
        annotation.coordinate = coordinate!
        self.mapView.addAnnotation(annotation)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            let coordinate = annotation.coordinate
            
            let destinationPlacemark = MKPlacemark(coordinate: coordinate)
            
            let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
            
            //Apple map
            MKMapItem.openMaps(with: [destinationMapItem], launchOptions: nil)
        }
    }
    
    
    //it fire when user enter a region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("did enter region")
    }
    
    //it fire when user exit a region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("did exit region")
    }
    
    //delegate method for overlay
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            var circleRender = MKCircleRenderer(circle: overlay as! MKCircle)
            circleRender.lineWidth = 1.0
            circleRender.strokeColor = UIColor.systemPink
            circleRender.fillColor = UIColor.systemPink
            circleRender.alpha = 0.4
            return circleRender
        }
        
        let render = MKPolylineRenderer(overlay: overlay)
        render.lineWidth = 5.0
        render.strokeColor = UIColor.systemBlue
        return render
        
        //if its not then default render
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        mapView.setRegion(region, animated: true)
    }

}

