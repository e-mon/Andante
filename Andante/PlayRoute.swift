//
//  PlayRoute.swift
//  Andante
//
//  Created by admin on 10/28/14.
//  Copyright (c) 2014 sadp. All rights reserved.
//

import Foundation
import CoreData

class PlayRoute: NSManagedObject {

    @NSManaged var userName: String
    @NSManaged var region: AnyObject
    @NSManaged var songName: String
    @NSManaged var artistName: AnyObject
    @NSManaged var timestamp: NSDate

}
