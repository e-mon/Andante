//
//  BackgroundPlayController.swift
//  Andante
//
//  Created by yubessy on 2014/10/23.
//  Copyright (c) 2014年 sadp. All rights reserved.
//

import CoreLocation
import MediaPlayer


class BackgroundPlayController: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let systemMusicPlayer = MPMusicPlayerController()
    private let playRouteManager = PlayRouteManager()

    internal var monitoredRegions: NSSet! {
        return self.locationManager.monitoredRegions
    }

    override init() {
        super.init()
        self.locationManager.delegate = self
    }

    internal func startMonitoringForRegions() {
        println("**startMonitoringForRegions**")
        let regions: [CLCircularRegion]! = self.playRouteManager.getAllRegion()
        for region in regions {
            self.locationManager.startMonitoringForRegion(region)
        }
    }

    internal func stopMonitoringForRegions() {
        println("**stopMonitoringForRegions**")
        let regions: NSSet! = self.monitoredRegions
        for region in regions {
            self.locationManager.stopMonitoringForRegion(region as CLRegion)
        }
    }

    /* CLLocationManagerDelegate methods */

    internal func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        println("**didEntereRegion**")
        println(region)

        // TODO: regionに対応するitemが何らかの理由で取り出せなかった場合のエラー処理
        let item: MPMediaItem! = self.playRouteManager.getMediaPlayItem(region as CLCircularRegion)
        let collection = MPMediaItemCollection(items: [item])
        self.systemMusicPlayer.setQueueWithItemCollection(collection)
        self.systemMusicPlayer.play()
    }

    internal func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        println("**monitoringDidFailForRegion**")
        println(region)
        println(error)
    }

    /* Debug methods */

    internal func _startMonitoringForExampleRegion() {
        println("**_startMonitoringForExampleRegion**")
        let coordinate = CLLocationCoordinate2D(latitude: 35.028459, longitude: 135.784227)
        let region = CLCircularRegion(center: coordinate, radius: 30.0, identifier: "LAWSON_IMADEGAWA")
        self.locationManager.startMonitoringForRegion(region)
    }
}
