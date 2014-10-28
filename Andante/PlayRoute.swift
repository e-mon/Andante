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

//CoreDataがobjcライブラリらしく、これがないとクラスを認識してくれない
@objc(PlayRoute)
class PlayRoute: NSManagedObject {

    @NSManaged var userName: String
    @NSManaged var region: CLRegion
    @NSManaged var songName: String
    @NSManaged var artistName: String
    //FIXME : インスタンスをいちいち生成してオブジェクトを保存するまでもないので、longで保存でいいかも。
    @NSManaged var timestamp: NSDate

}
