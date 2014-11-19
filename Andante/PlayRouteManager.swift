//
//  PlayRouteManager.swift
//  Andante
//
//  Created by emon on 10/28/14.
//  Copyright (c) 2014 sadp. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import MediaPlayer

class PlayRouteManager{
    
    // debugWrite
    func _writeCoreData(region : CLCircularRegion, songName : String, artistName : String, userName : String)->Bool{
        
        let playroute = NSEntityDescription.insertNewObjectForEntityForName("PlayRoute", inManagedObjectContext: managedObjectContext!) as PlayRoute
        playroute.userName = userName
        playroute.region = region
        playroute.timestamp = NSDate()
        
        var savingError: NSError?
        if managedObjectContext!.save(&savingError){
            println("Successfully saved the new songName")
        }else{
            if let error = savingError{
                println("Failed to save the new person. Error = \(error)")
            }
        }
        return true
    }
    
    // debugRead
    func _readCoreData() -> Bool{
        let fetchRequest = NSFetchRequest(entityName: "PlayRoute")
        var requestError: NSError?
        
        /* And execute the fetch request on the context */
        let playroutes = managedObjectContext!.executeFetchRequest(fetchRequest,
            error: &requestError) as [PlayRoute!]
        
        /* Make sure we get the array */
        if playroutes.count > 0{
            
            var counter = 1
            for playroute in playroutes{
                
                println("playroute \(counter) songName = \(playroute.userName)")
                println("playroute \(counter) region = \(playroute.region)")
                println("playroute \(counter) songName = \(playroute.timestamp)")
                
                counter++
            }
            
        } else {
            println("Could not find any Person entities in the context")
        }
        
        return true
        
    }
    
    internal func getAllRegion() -> [CLCircularRegion]?{
        let playroutes = fetchRequestToPlayRoute(nil)
        
        var regions : [CLCircularRegion] = []
        
        if playroutes?.count > 0 {
            for pr in playroutes!{
                regions.append(pr.region)
            }
            return regions
        }else{
            return nil
        }
    }
    
    internal func getPlayRoutes()->[PlayRoute]?{
        return fetchRequestToPlayRoute(nil)
    }
    
    internal func getMediaPlayItem(region : CLCircularRegion) -> MPMediaItem?{
        
        let playroutes = fetchRequestToPlayRoute(NSPredicate(format: "region = %@",region))
        
        if playroutes?.count > 0 {
            // FIXME: 1件以上存在することは仕様上ありえないが，一応先頭要素を返す．煮詰める必要アリ
            return playroutes![0].media
        }else{
            return nil
        }
    }

    /* centerを中心とした20m四方の空間内に存在するRegionを検索し，返す*/
    internal func getMediaPlayItem(center : CLLocationCoordinate2D) -> MPMediaItem?{
        
        let pi:Double = 3.14159265359
        let globalRadius:Double = 6378150.0
        let metrePerLatitude:Double = 2.0*pi*globalRadius/360.0
        let metrePerLongitude:Double = globalRadius*cos(center.latitude/180.0*pi)*2.0*pi/360.0
        let side:Double = 20 //20m四方に設定
        let bottomLatitude = center.latitude - (side/2.0)/metrePerLatitude
        let topLatitude = center.latitude + (side/2.0)/metrePerLatitude
        let rightLongitude = center.longitude - (side/2.0)/metrePerLongitude
        let leftLongitude = center.longitude + (side/2.0)/metrePerLongitude
        
        let format = "latitude >= %f AND latitude <= %f AND longitude >= %f AND longitude <= %f"
        let playroutes = fetchRequestToPlayRoute(NSPredicate(format:format,bottomLatitude,topLatitude,rightLongitude,leftLongitude))

        if playroutes?.count > 0 {
            // FIXME: 先頭要素を返す．煮詰める必要アリ
            return playroutes![0].media
        }else{
            return nil
        }
    }
    
    internal func setPlayRoute(region : CLCircularRegion, media : MPMediaItem,  userName : String) -> Bool{
        let playroute = NSEntityDescription.insertNewObjectForEntityForName("PlayRoute", inManagedObjectContext: managedObjectContext!) as PlayRoute
        playroute.media = media
        playroute.userName = userName
        playroute.region = region
        playroute.timestamp = NSDate()
        playroute.latitude = region.center.latitude
        playroute.longitude = region.center.longitude
        
        var savingError: NSError?
        if !managedObjectContext!.save(&savingError){
            // FIXME: エラーハンドリングができてないので要修正
            if let error = savingError{
                println("Failed to save the new playroute. Error = \(error)")
            }
            return false
        }
        return true
    }
    
    private func fetchRequestToPlayRoute(predicate : NSPredicate?)->[PlayRoute]?{
        let fetchRequest = NSFetchRequest(entityName: "PlayRoute")
        var requestError: NSError?
        
        fetchRequest.returnsObjectsAsFaults = false;
        fetchRequest.predicate = predicate?
        
        let playroutes = managedObjectContext!.executeFetchRequest(fetchRequest, error: &requestError) as [PlayRoute]?
       
        if playroutes?.count > 0 {
            return playroutes!
        }else{
            return nil
        }
    }

    // MARK: - Core Data stack

    private lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "sadp.CoreDataTest" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
        }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        //for Appgroup setting
        var storeURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.Andante")
        storeURL = storeURL!.URLByAppendingPathComponent("PlayRoute.sqlite");
        //let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CoreDataTest.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    private lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    private func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
}
