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

    private var lastHitLocation: CLLocation?
    private var lastPlayedMediaItem: MPMediaItem?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    internal func startUpdatingLocation() {
        println("**startUpdatingLocation**")
        self.locationManager.startUpdatingLocation()
    }

    internal func stopUpdatingLocation() {
        println("**stopUpdatingLocation**")
        self.locationManager.stopUpdatingLocation()
    }

    /* CLLocationManagerDelegate methods */

    internal func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("**didUpdateLocations**")
        let newestLocation: CLLocation = locations.last as CLLocation
        println(newestLocation)

        // TODO: 以下の場合の挙動については詳しく考える必要あり
        // * 既に曲が再生中
        //     * その曲がAndanteによって再生された
        //     * その曲が他のアプリによって再生された
        // とりあえず現在は何も再生していない場合にのみ再生を開始する

        if self.systemMusicPlayer.playbackState == MPMusicPlaybackState.Playing  {
            println("--already playing another item--")
            return
        }

        // TODO: MediaItemの読み出し
        if let item: MPMediaItem = nil { // self.playRouteManager.getMediaPlayItem(newestLocation.coordinate)
            println("--item found--")
            println(item)

            let collection = MPMediaItemCollection(items: [item])
            self.systemMusicPlayer.setQueueWithItemCollection(collection)
            self.systemMusicPlayer.play()

            self.lastHitLocation = newestLocation
            self.lastPlayedMediaItem = item
        } else {
            println("--item not found--")
        }
    }
}
