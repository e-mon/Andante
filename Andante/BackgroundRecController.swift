//
//  BackgroundRecController.swift
//  Andante
//
//  Created by Unyol Lee on 14.10.29.
//  Copyright (c) 2014 sadp. All rights reserved.
//

import Foundation
import CoreLocation
import MediaPlayer

class BackgroundRecController : NSObject, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    
    func startUpdateLocation() {
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.NotDetermined) {
            locationManager.requestAlwaysAuthorization()
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdateLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    //　automatically called updating location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        self.saveIntoDB(manager)
    }
    
    func saveIntoDB(manager: CLLocationManager) {
        var systemMusicPlayer = MPMusicPlayerController()
        
        if(systemMusicPlayer.playbackState.hashValue == 1 && (10 == Int(systemMusicPlayer.currentPlaybackTime))){
            println(systemMusicPlayer.nowPlayingItem.artist)
            println(systemMusicPlayer.nowPlayingItem.title)
            println(systemMusicPlayer.currentPlaybackTime)
            
            let prm = PlayRouteManager()
            
            let clc = CLLocationCoordinate2D(latitude: manager.location.coordinate.latitude, longitude: manager.location.coordinate.longitude)
            let region : CLRegion = CLCircularRegion(center: clc, radius: 20.0, identifier: "test1")
            prm.setPlayRoute(region, media: systemMusicPlayer.nowPlayingItem, lat: manager.location.coordinate.latitude, lng: manager.location.coordinate.longitude, radius: 20.0, userName: "userName")
        }
    }
}