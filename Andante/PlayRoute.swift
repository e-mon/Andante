//
//  PlayRoute.swift
//  Andante
//
//  Created by admin on 10/28/14.
//  Copyright (c) 2014 sadp. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import MediaPlayer

// CoreDataがobjcライブラリらしく、これがないとクラスを認識してくれない
@objc(PlayRoute)
class PlayRoute: NSManagedObject {

    @NSManaged var userName: String
    @NSManaged var region: CLRegion
    @NSManaged var media : MPMediaItem
    @NSManaged var lat : Double
    @NSManaged var lng : Double
    @NSManaged var radius : Double
    @NSManaged var timestamp: NSDate
}
