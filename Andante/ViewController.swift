//
//  ViewController.swift
//  Andante
//
//  Created by admin on 2014/10/22.
//  Copyright (c) 2014年 sadp. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import MediaPlayer

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var PlayButton: UIBarButtonItem!
    @IBOutlet weak var RecordButton: UIBarButtonItem!
    @IBOutlet weak var StopButton: UIBarButtonItem!
    @IBOutlet weak var myMapView: MKMapView!

    private let backgroundPlayController = BackgroundPlayController()
    private let backgroundRecController = BackgroundRecController()
    var myLocationManager: CLLocationManager!
    
    // 0:stop 1:play 2:record 良くない書き方
    private var state = 0
    
    //アートワーク表示用に、MKPointAnnotationをカスタムしたクラスを宣言
    class CustomPointAnnotation: MKPointAnnotation {
        var artwork: MPMediaItemArtwork!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // mapの初期化及び表示
        mapInit()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willEnterForeground:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        willEnterForeground(nil)
    }

    func mapInit(){
        myLocationManager = CLLocationManager()
        myLocationManager.delegate = self
        myMapView.delegate = self
        
        // 10m移動したら位置情報を更新する
        myLocationManager.distanceFilter = 10.0
        
        // 精度を最高精度にする
        myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // セキュリティ認証のステータスを取得
        // まだ認証が得られていない場合は、認証ダイアログを表示
        if(CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined) {
            self.myLocationManager.requestAlwaysAuthorization();
        }
        
        // 位置情報の更新を開始
        myLocationManager.startUpdatingLocation()
        
        //自分の位置を画面中央に表示
        myMapView.showsUserLocation = true
        myMapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
        // MapViewをViewに追加
        self.view.addSubview(myMapView)
        // myMapViewを最背面へ
        self.view.sendSubviewToBack(myMapView)
        
        // 初期状態はStop
        StopButton.tintColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1)
    }

    func willEnterForeground(notification: NSNotification!)  {
        var playRoute:PlayRouteManager! = PlayRouteManager()
        let playroutelist = playRoute.getPlayRoutes()
        
        if (playroutelist != nil){
            for pl in playroutelist!{
                
                var info: CustomPointAnnotation = CustomPointAnnotation()
                
                let myPinLatitude: CLLocationDegrees = pl.latitude
                let myPinLongitude: CLLocationDegrees = pl.longitude
                let Pincenter: CLLocationCoordinate2D = CLLocationCoordinate2DMake(myPinLatitude, myPinLongitude)
                
                info.coordinate = Pincenter //表示位置
                info.title = pl.media.title // タイトル「曲名」
                info.subtitle = pl.media.artist // サブタイトル「アーティスト名」
                info.artwork = pl.media.artwork//アートワーク
                
                println("title : \(info.title)") //デバッグ用
                
                myMapView.addAnnotation(info)
            }
        }
    }
    
    // addAnnotation時に呼び出される
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        if !(annotation is CustomPointAnnotation) {
            return nil
        }
        
        let reuseId = "test"
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView.canShowCallout = true
        }
        else {
            anView.annotation = annotation
        }
        
        //Set annotation-specific properties **AFTER**
        //the view is dequeued or created...
        
        let cpa = annotation as CustomPointAnnotation
        
        if cpa.artwork != nil {
            println("artwork : \(cpa.artwork.bounds.size)")
            // とりあえず40×40で表示
            var h = 40
            var w = 40
            
            // 角丸化
            anView.image = Toucan(image: cpa.artwork.imageWithSize(CGSize(width: w,height: h))).maskWithRoundedRect(cornerRadius: 10).image
        }
        return anView
    }

    // 表示範囲が変更された時に呼び出される
    // 地図の中心点の経度緯度を取得する
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        
        let presentCenter: CLLocationCoordinate2D = myMapView.centerCoordinate
        let lat: Double = presentCenter.latitude
        let lon: Double = presentCenter.longitude
        
        println("regionDidChangeAnimated=緯度：\(lat)　経度：\(lon)")
    }
    
    
    // 認証が変更された時に呼び出される
    // 認証ステータスをプリントする
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status{
        case .AuthorizedWhenInUse:
            println("AuthorizedWhenInUse")
        case .Authorized:
            println("Authorized")
        case .Denied:
            println("Denied")
        case .Restricted:
            println("Restricted")
        case .NotDetermined:
            println("NotDetermined")
        default:
            println("etc.")
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func PlayButton(sender: UIBarButtonItem) {
        if state != 1 {
            println("Play")
            PlayButton.tintColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1)
            RecordButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            StopButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        
            self.backgroundRecController.stopUpdateLocation()
            self.backgroundPlayController.startUpdatingLocation()
            state = 1
        }
    }

    @IBAction func RecordButton(sender: UIBarButtonItem) {
        if state != 2{
            println("Record")
            PlayButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            RecordButton.tintColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1)
            StopButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        
            self.backgroundPlayController.stopUpdatingLocation()
            self.backgroundRecController.startUpdateLocation()
            state = 2
        }
    }
    
    @IBAction func StopButton(sender: UIBarButtonItem) {
        if state != 0 {
            println("Stop")
            PlayButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            RecordButton.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            StopButton.tintColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1)
            
            self.backgroundPlayController.stopUpdatingLocation()
            self.backgroundRecController.stopUpdateLocation()
            state = 0
        }
    }
    
    @IBAction func CurrentPositionButton(sender: UIBarButtonItem) {
        println("Pos")
        
        //実装してみた。ちゃんと動く
        myMapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
    }
    
    
}
