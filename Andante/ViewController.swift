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

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, SphereMenuDelegate, BackgroundRecDelegate {

    @IBOutlet weak var myMapView: MKMapView!
    
    private var MenuIcon: UIImage!
    private var PlayIcon: UIImage!
    private var RecordIcon: UIImage!
    private var StopIcon: UIImage!
    private var PositionIcon: UIImage!

    private let backgroundPlayController = BackgroundPlayController()
    private let backgroundRecController = BackgroundRecController()
    var myLocationManager: CLLocationManager!
    
    // 0:PlayMode 1:RecordMode 2:StopMode 良くない書き方
    private var state = 2
    
    //アートワーク表示用に、MKPointAnnotationをカスタムしたクラスを宣言
    class CustomPointAnnotation: MKPointAnnotation {
        var artwork: MPMediaItemArtwork!
    }
    
    
    //画面が表示された後に呼び出される
    //マップにアートワークを表示する
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        println("viewDidAppear")
        showSongInfo()
    }
    
    func showSongInfo(){
        println("show song infos on map")
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
    
    //画像表示用にaddAnnotationから呼ばれる
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
            
            //アートワークサイズを32に固定
            let h = 32
            let w = 32
            
            //アートワークのデザインを角丸に設定
            anView.image = Toucan(image: cpa.artwork.imageWithSize(CGSize(width: w,height: h))).maskWithRoundedRect(cornerRadius: 10).image
        }
        return anView
    }
    
    
    //初回ロード時のみ呼び出される
    //起動時に、現在地を画面中央に表示する
    override func viewDidLoad() {
        super.viewDidLoad()
            
        // LocationManagerの生成
        myLocationManager = CLLocationManager()
        
        // Delegateの設定
        myLocationManager.delegate = self
        backgroundRecController.delegate = self
        
        // 10m移動したら位置情報を更新する
        myLocationManager.distanceFilter = 10.0
        
        // 精度を最高精度にする
        myLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // セキュリティ認証のステータスを取得
        let status = CLLocationManager.authorizationStatus()
        
        // まだ認証が得られていない場合は、認証ダイアログを表示
        if(status == CLAuthorizationStatus.NotDetermined) {
            
            // まだ承認が得られていない場合は、認証ダイアログを表示
            self.myLocationManager.requestAlwaysAuthorization();
        }
        
        // 位置情報の更新を開始
        myLocationManager.startUpdatingLocation()
        
        // Delegateを設定
        myMapView.delegate = self
        
        //自分の位置を画面中央に表示
        myMapView.showsUserLocation = true
        myMapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
        
        // MapViewをViewに追加
        self.view.addSubview(myMapView)
        // myMapViewを最背面へ
        self.view.sendSubviewToBack(myMapView)
        
        // 現在地ボタン
        let PositionIcon = UIImage(named: "PositionIcon") as UIImage!
        let imageButton   = UIButton()
        imageButton.tag = 4
        imageButton.frame = CGRectMake(0, 0, 128, 128)
        imageButton.layer.position = CGPoint(x: self.view.frame.width/2+100, y:500)
        imageButton.setImage(PositionIcon, forState: .Normal)
        imageButton.addTarget(self, action: "PositionIconTapped:", forControlEvents:.TouchUpInside)
        self.view.addSubview(imageButton)
        
        // SphereMenuUI
        MenuIcon = UIImage(named: "StopIcon-on")
        PlayIcon = UIImage(named: "PlayIcon-off")
        RecordIcon = UIImage(named: "RecordIcon-off")
        StopIcon = UIImage(named: "StopIcon-on")
        
        var images:[UIImage] = [PlayIcon!,RecordIcon!,StopIcon!]
        var menu = SphereMenu(startPoint: CGPointMake(260, 420), startImage: MenuIcon!, submenuImages:images)
        menu.delegate = self
        self.view.addSubview(menu)
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

    
    func sphereDidSelected(index: Int) {
        println("index = \(index)")
        // ひよコードです
        switch index {
            case 0:
                if state != 0 {
                    println("Play")
                    MenuIcon = UIImage(named: "PlayIcon-on")
                    PlayIcon = UIImage(named: "PlayIcon-on")
                    RecordIcon = UIImage(named: "RecordIcon-off")
                    StopIcon = UIImage(named: "StopIcon-off")
                    
                    var images:[UIImage] = [PlayIcon!,RecordIcon!,StopIcon!]
                    var menu = SphereMenu(startPoint: CGPointMake(260, 420), startImage: MenuIcon!, submenuImages:images)
                    menu.delegate = self
                    self.view.addSubview(menu)
                
                    self.backgroundRecController.stopUpdateLocation()
                    self.backgroundPlayController.startUpdatingLocation()
                    state = 0
                }
            case 1:
                if state != 1 {
                    println("Record")
                    MenuIcon = UIImage(named: "RecordIcon-on")
                    PlayIcon = UIImage(named: "PlayIcon-off")
                    RecordIcon = UIImage(named: "RecordIcon-on")
                    StopIcon = UIImage(named: "StopIcon-off")
                    
                    var images:[UIImage] = [PlayIcon!,RecordIcon!,StopIcon!]
                    var menu = SphereMenu(startPoint: CGPointMake(260, 420), startImage: MenuIcon!, submenuImages:images)
                    menu.delegate = self
                    self.view.addSubview(menu)
                    
                    self.backgroundPlayController.stopUpdatingLocation()
                    self.backgroundRecController.startUpdateLocation()
                    state = 1
                }
            case 2:
                if state != 2 {
                    println("Stop")
                    MenuIcon = UIImage(named: "StopIcon-on")
                    PlayIcon = UIImage(named: "PlayIcon-off")
                    RecordIcon = UIImage(named: "RecordIcon-off")
                    StopIcon = UIImage(named: "StopIcon-on")
                    
                    var images:[UIImage] = [PlayIcon!,RecordIcon!,StopIcon!]
                    var menu = SphereMenu(startPoint: CGPointMake(260, 420), startImage: MenuIcon!, submenuImages:images)
                    menu.delegate = self
                    self.view.addSubview(menu)
                    
                    self.backgroundPlayController.stopUpdatingLocation()
                    self.backgroundRecController.stopUpdateLocation()
                    state = 2
                }

            default:
                break
        }
        
    }
    
    func PositionIconTapped(sender: UIButton){
        println("Pos")
        //実装してみた。ちゃんと動く
        myMapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
    }

    
}
