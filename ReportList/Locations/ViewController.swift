//
//  ViewController.swift
//  ReportList
//
//  Created by Naresh kumar Nagulavancha on 3/27/19.
//  Copyright © 2019 Naresh kumar Nagulavancha. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreData

class ViewController: UIViewController {

    var locationManager = CLLocationManager()
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var helperView: UIView!
    @IBOutlet var ownerLabel: UILabel!
    @IBOutlet var addressLabel1: UILabel!
    @IBOutlet var saveButton: DropDownButton!
    
    
    let chooseCategory = DropDown()
    var tempLocationDetails: LocationDetails? = nil
    var viewModel: LocationViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        helperView.layer.cornerRadius = 5
        
        setUpCategory()
        
        // Do any additional setup after loading the view.
        self.mapView.mapType = .hybrid
        self.mapView.delegate = self
        
        //Location Manager code to fetch current location
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
        mapView.padding = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 16)
        
        GetOrganization().execute(onSuccess: { (location: OrganizationResponse) in
            print(location)
        }, onError: { (error) in
            print(error)
        })
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        helperView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    @IBAction func save(_ sender: Any) {
        chooseCategory.show()
    }
    
    func setUpCategory() {
        chooseCategory.anchorView = saveButton
    
        chooseCategory.bottomOffset = CGPoint(x: 0, y: saveButton.bounds.height)
        
        chooseCategory.dataSource = ["Distressed Commercial", "Commercial Lot", "Retail/Car Wash Site", "Triple Net Lease Site", "Apartments", "Hotel", "Developer", "Distressed Residential", "Residential Lots"]
        
        chooseCategory.selectionAction = { [weak self] (index, item) in
            if let self = self, let viewModel = self.viewModel {
                if let item = self.chooseCategory.selectedItem {
                    viewModel.setCategory(cat: item)
                      } else {
                    viewModel.setCategory(cat: "N/A")
                }
                viewModel.save() { result in
                    if !result {
                        let alert = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                        alert.addAction(alertAction)
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        viewModel.sendAllRequests()
                    }
                }
            }
        }
    }
    
}

extension ViewController: CLLocationManagerDelegate {
   
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)
        
        self.mapView?.animate(to: camera)
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.locationManager.stopUpdatingLocation()
        
    }

}

extension ViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.helperView.isHidden = true
        view.endEditing(true)
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        print("Coordinates: \(coordinate.latitude), \(coordinate.longitude)")
        mapView.clear()
        var locationService = GetLocation()
        locationService.params["spatial_intersect"] = "POINT(\(coordinate.longitude) \(coordinate.latitude))"
        locationService.execute(onSuccess: { (location: LocationDetails) in
            // Do something with users
            let path = GMSMutablePath()
            let coordinates = location.results?.first?.geom_as_wkt
            
            guard let locations = coordinates  else {
                return
            }
            for i in locations.getLocations() {
                path.add(i)
            }
            
            self.viewModel = LocationViewModel(location: location, category: "", point: coordinate, points: locations.getLocations())
            let addresses = self.viewModel!.getAdress()
            DispatchQueue.main.async {
                self.ownerLabel.text = location.results?.first?.owner ?? "Not available"
                self.addressLabel1.text = "\(addresses.0) \(addresses.2)"
            }
            
            let polyLine = GMSPolyline(path: path)
            polyLine.strokeColor = UIColor.red
            polyLine.strokeWidth = polyLine.strokeWidth + 1
            polyLine.map = mapView
            if self.helperView.isHidden {
                UIView.animate(withDuration: 0.2, animations: {
                    self.helperView.isHidden = false
                })
            }
        },
                                onError: { (error: Error) in
                                    // Do something with error
                                    print(error)
        })
    }
}


