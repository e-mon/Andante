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
    var locationManager: CLLocationManager!
    var systemMusicPlayer: MPMusicPlayerController?

    override init() {
        super.init()

        locationManager.delegate = self
        systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()

        let regions = getRegisteredRegionsFromCoreData()
        startMonitoringForRegions(regions)
    }

    func getRegisteredRegionsFromCoreData() -> [CLRegion] {
        return [CLRegion()] //  TODO Implementation
    }

    func startMonitoringForRegions(regions: [CLRegion]) {
        for region in regions {
            locationManager.startMonitoringForRegion(region)
        }
    }

    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        let mediaItemCollection = getMediaItemCollectionByRegion(region)
        systemMusicPlayer?.setQueueWithItemCollection(mediaItemCollection)
        systemMusicPlayer?.play()
    }

    func getMediaItemCollectionByRegion(region: CLRegion) -> MPMediaItemCollection {
        return MPMediaItemCollection(items: [MPMediaItem()]) //  TODO Implementation
    }
}
