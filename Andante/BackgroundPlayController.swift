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
    private var lastPlayedMediaItem: MPMediaItem!

    private let minDistance = 10.0

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    internal func startUpdatingLocation() {
        self.lastHitLocation = nil
        self.lastPlayedMediaItem = nil
        self.locationManager.startUpdatingLocation()
    }

    internal func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
    }

    /* CLLocationManagerDelegate methods */

    internal func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        let newestLocation: CLLocation = locations.last as CLLocation

        if self.lastHitLocation != nil && self.lastHitLocation.distanceFromLocation(newestLocation) < self.minDistance {
            return
        }

        // TODO: 以下の場合の挙動については詳しく考える必要あり
        // * 既に曲が再生中
        //     * その曲がAndanteによって再生された
        //     * その曲が他のアプリによって再生された
        // とりあえず現在はsystemMusicPlayerがStoppedまたはPausedの場合のみ再生を開始する

        let state: MPMusicPlaybackState = self.systemMusicPlayer.playbackState
        if state != MPMusicPlaybackState.Stopped && state != MPMusicPlaybackState.Paused {
            return
        }

        let item: MPMediaItem! = self.playRouteManager.getMediaPlayItem(newestLocation.coordinate, side: 40.0)

        if item == nil {
            return
        }

        if self.lastPlayedMediaItem != nil && item == self.lastPlayedMediaItem {
            return
        }

        let collection = MPMediaItemCollection(items: [item])
        self.systemMusicPlayer.setQueueWithItemCollection(collection)
        self.systemMusicPlayer.play()

        self.lastHitLocation = newestLocation
        self.lastPlayedMediaItem = item
    }
}
