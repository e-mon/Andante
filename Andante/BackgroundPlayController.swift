//
//  BackgroundPlayController.swift
//  Andante
//
//  Created by yubessy on 2014/11/17.
//  Copyright (c) 2014年 sadp. All rights reserved.
//

import Foundation
import CoreLocation
import MediaPlayer


class BackgroundPlayController: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let systemMusicPlayer = MPMusicPlayerController()
    private let playRouteManager = PlayRouteManager()

    private var lastHitLocation: CLLocation!
    private var lastPlayedItem: MPMediaItem!

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    internal func startUpdatingLocation() {
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.NotDetermined {
            locationManager.requestAlwaysAuthorization()
        }

        self.lastHitLocation = nil
        self.lastPlayedItem = nil
        self.locationManager.startUpdatingLocation()
    }

    internal func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
    }

    /* CLLocationManagerDelegate methods */

    internal func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        // TODO: 以下の場合の挙動については詳しく考える必要あり
        // * 既に曲が再生中
        //     * その曲がAndanteによって再生された
        //     * その曲が他のアプリによって再生された
        // とりあえず現在はsystemMusicPlayerがStoppedまたはPausedの場合のみ再生を開始する
        let state: MPMusicPlaybackState = self.systemMusicPlayer.playbackState
        if state != MPMusicPlaybackState.Stopped && state != MPMusicPlaybackState.Paused {
            return
        }

        let newestLocation: CLLocation = locations.last as CLLocation
        let newItem: MPMediaItem! = self.playRouteManager.getMediaPlayItem(newestLocation.coordinate, side: 40.0)

        if newItem == nil {
            return
        }

        if self.lastPlayedItem != nil && newItem == self.lastPlayedItem {
            return
        }

        let collection = MPMediaItemCollection(items: [newItem])
        self.systemMusicPlayer.setQueueWithItemCollection(collection)
        self.systemMusicPlayer.play()

        self.lastHitLocation = newestLocation
        self.lastPlayedItem = newItem
    }
}
