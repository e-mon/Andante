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
    
    func setLocationManager(){
        locationManager.delegate = self
        //    locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }
    
    // Rec, Play
    func startUpdateLocation() {
        locationManager.startUpdatingLocation()
    }
    // Off
    func stopUpdateLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    
    // automatically called updating location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.printLatitudeLongitude(manager)
        // music song change notification catch
    }
    
    
    // temporary method -> print, latitude, longitude, time, StandardTime
    func printLatitudeLongitude(manager: CLLocationManager) {
        println(manager.location)
        println(manager.location.coordinate.latitude)
        println(manager.location.coordinate.longitude)
    }

//    save [latitude, longitude, time, songName(songID)] into DB, when SONG CHANGE
    func saveIntoDB(manager: CLLocationManager) {
        var latitude = manager.location.coordinate.latitude
        var longitude = manager.location.coordinate.longitude
        var timestamp = manager.location.timestamp
//        manager.location.speed
//        var newSong
    }
    
}