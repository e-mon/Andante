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
    internal var delegate: BackgroundRecDelegate?

    private let locationManager = CLLocationManager()
    private let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
    private let playRouteManager = PlayRouteManager()

    private var lastPlayedItem: MPMediaItem!

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    internal func startUpdateLocation() {
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }

        self.locationManager.startUpdatingLocation()
    }
    
    internal func stopUpdateLocation() {
        self.locationManager.stopUpdatingLocation()
    }

    /* CLLocationManagerDelegate methods */

    internal func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let nowPlayingItem: MPMediaItem! = self.systemMusicPlayer.nowPlayingItem
        let state: MPMusicPlaybackState = self.systemMusicPlayer.playbackState
        
        if state != MPMusicPlaybackState.Paused {
            return
        }
        
        if nowPlayingItem == nil {
            return
        }

        if self.lastPlayedItem != nil && nowPlayingItem == self.lastPlayedItem {
            return
        }

        let newestLocation: CLLocation = locations.last as CLLocation
        let latitude: CLLocationDegrees = newestLocation.coordinate.latitude
        let longitude: CLLocationDegrees = newestLocation.coordinate.longitude
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = CLCircularRegion(center: coordinate, radius: 20.0, identifier: "test1")
        self.playRouteManager.setPlayRoute(region, media: nowPlayingItem, userName: "userName")

        self.lastPlayedItem = nowPlayingItem

        // リアルタイム表示
        self.delegate?.showSongInfo()
    }
}
