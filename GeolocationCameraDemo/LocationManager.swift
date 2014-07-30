//
//  LocationManager.swift
//  GeolocationCameraDemo
//
//  Created by Fumitoshi Ogata on 2014/07/30.
//  Copyright (c) 2014年 Fumitoshi Ogata. All rights reserved.
//
import CoreLocation

protocol LocationControllerDelegate {
    func didUpdateLocation(location: CLLocation)
}

class LocationController: NSObject, CLLocationManagerDelegate {
    
    var coreLocation = CLLocationManager()
    var delegate: LocationControllerDelegate?
    
    init() {
        super.init()
        setupCoreLocation()
    }
    
    func coreLocationAvailable() -> Bool {
        if (CLLocationManager.locationServicesEnabled()) {
            return true
        } else {
            println("ERROR: Location is NOT available")
            return false
        }
    }
    
    func setupCoreLocation() {
        if (coreLocationAvailable()) {
            coreLocation.delegate = self
            coreLocation.startUpdatingLocation()
        }
    }
    
    func deg2rad(deg : Double) -> Double {  
        return deg * (M_PI/180) as Double
    }
    
    func getDistanceFromLocation(locationA : CLLocation) -> Double {
        
        var locationB = CLLocation(latitude:35.658987,longitude:139.702776)
        
        var latiA = locationA.coordinate.latitude  as Double
        var longA = locationA.coordinate.longitude as Double
        var latiB = locationB.coordinate.latitude  as Double
        var longB = locationB.coordinate.longitude as Double
        
        //地球の半径
        var earthR = 6378.137
        
        //緯度・緯度の差をラジアンにする
        var diffLati = self.deg2rad(latiB - latiA)
        var diffLong = self.deg2rad(longB - longA)
        
        //南北の距離を求める
        var distOfNorthAndSouth = earthR * diffLati
        
        //東西の距離を求める
        var distOfEastAndWest = cos(deg2rad(latiA)) * earthR * diffLong
        
        //直線の距離を三平方の定理を使って出す
        var d : Double = sqrt(pow(distOfEastAndWest,2) + pow(distOfNorthAndSouth,2))
        
        return d
    }
    
    func locationManager(manager: CLLocationManager!,
        didUpdateLocations locations: AnyObject[]!) {
            for location in locations as CLLocation[] {
                //ロケーションを更新する
                delegate?.didUpdateLocation(location)
                var distance = self.getDistanceFromLocation(location)   
            }
    }
    
    
    
    func locationManager(manager: CLLocationManager!,
        didFailWithError error: NSError!) {
            println("ERROR: Failed to get location");
    }
}