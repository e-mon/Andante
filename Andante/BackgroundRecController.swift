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


protocol BackgroundRecDelegate{
    func showSongInfo()
}


class BackgroundRecController: NSObject, CLLocationManagerDelegate {
    var lastPlayedMusic: MPMediaItem!
    let locationManager = CLLocationManager()
    var delegate: BackgroundRecDelegate?

    func startUpdateLocation() {
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.NotDetermined {
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
        if systemMusicPlayer.nowPlayingItem == nil {
            return
        }

        if lastPlayedMusic == nil {
            lastPlayedMusic = systemMusicPlayer.nowPlayingItem
        }

        if !lastPlayedMusic.isEqual(systemMusicPlayer.nowPlayingItem) {
            lastPlayedMusic = systemMusicPlayer.nowPlayingItem
            let prm = PlayRouteManager()

            let clc = CLLocationCoordinate2D(latitude: manager.location.coordinate.latitude, longitude: manager.location.coordinate.longitude)
            let region = CLCircularRegion(center: clc, radius: 20.0, identifier: "test1")
            prm.setPlayRoute(region, media: systemMusicPlayer.nowPlayingItem, userName: "userName")
            delegate?.showSongInfo()
        }
    }
}
