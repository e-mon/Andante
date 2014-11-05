//
//  BackgroundRecController.swift
//  Andante
//
//  Created by Unyol Lee on 14.10.29.
//  Copyright (c) 2014 sadp. All rights reserved.
//

import Foundation
import CoreLocation

class BackgroundRecController : NSObject, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    
    func startUpdateLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdateLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    //　automatically called updating location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.printLatitudeLongitude(manager)
        // music song change notification catch will be below
        // saveIntoDB(manager)
    }
    
    //　temporary method -> print, latitude, longitude, time, StandardTime
    func printLatitudeLongitude(manager: CLLocationManager) {
        println(manager.location)
        println(manager.location.coordinate.latitude)
        println(manager.location.coordinate.longitude)
    }

    //　save [latitude, longitude, time, songName, artistName, userName] into DB, when SONG CHANGE
    func saveIntoDB(manager: CLLocationManager) {
        var timestamp = manager.location.timestamp
        
        let prm = PlayRouteManager()
        
        let clc = CLLocationCoordinate2D(latitude: manager.location.coordinate.latitude, longitude: manager.location.coordinate.longitude)
        let region : CLRegion = CLCircularRegion(center: clc, radius: 20.0, identifier: "test1")
        
        prm.setRegion(region1, songName: "testSong1", artistName: "artist1", userName: "user1")
        
        for pr in prm{
            println(pr.songName) // -> testSong
        }
    }
}
