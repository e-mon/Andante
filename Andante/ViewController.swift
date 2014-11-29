//
//  ViewController.swift
//  Andante
//
//  Created by admin on 2014/10/22.
//  Copyright (c) 2014年 sadp. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import MediaPlayer


// アートワーク表示用に、MKPointAnnotationをカスタムしたクラスを宣言
private class CustomPointAnnotation: MKPointAnnotation {
    var media: MPMediaItem!
    var overlay : MKOverlay!
}


class ViewController: UIViewController, MKMapViewDelegate, SphereMenuDelegate, BackgroundRecDelegate {
    @IBOutlet private weak var mapView: MKMapView!

    private let backgroundPlayController = BackgroundPlayController()
    private let backgroundRecController = BackgroundRecController()
    private let playRouteManager = PlayRouteManager()

    private var menuIcon: UIImage!
    private var playIcon: UIImage!
    private var recordIcon: UIImage!
    private var stopIcon: UIImage!

    private lazy var currentPositionButton: UIButton! = {
        let button = UIButton()
        button.tag = 4
        button.frame = CGRectMake(0, 0, 128, 128)
        button.layer.position = CGPoint(x: self.view.frame.width/2 + 120, y: 530)
        button.setImage(UIImage(named: "PositionIcon"), forState: .Normal)
        button.addTarget(self, action: "PositionIconTapped:", forControlEvents: .TouchUpInside)
        return button
    }()

    // 0:PlayMode 1:RecordMode 2:StopMode 良くない書き方
    private var state = 2

    // 起動時に現在地を画面中央に表示する。初回ロード時のみ呼び出される
    override internal func viewDidLoad() {
        super.viewDidLoad()

        // 位置情報の取得が許可されているか確認し、されていなければ許可を求める
        let locationManager = CLLocationManager()
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.NotDetermined) {
            locationManager.requestAlwaysAuthorization();
        }

        // delegateの設定
        self.backgroundRecController.delegate = self
        self.mapView.delegate = self

        //自分の位置を画面中央に表示
        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)

        // MapViewをViewに追加して再背面へ
        self.view.addSubview(self.mapView)
        self.view.sendSubviewToBack(self.mapView)

        // 現在地ボタンをViewに追加
        self.view.addSubview(self.currentPositionButton)

        // SphereMenuUI
        self.menuIcon = UIImage(named: "StopIcon-on")
        self.playIcon = UIImage(named: "PlayIcon-off")
        self.recordIcon = UIImage(named: "RecordIcon-off")
        self.stopIcon = UIImage(named: "StopIcon-on")

        let images: [UIImage] = [self.playIcon!, self.recordIcon!, self.stopIcon!]
        let menu = SphereMenu(startPoint: CGPointMake(self.view.frame.width/2+120, 460), startImage: self.menuIcon!, submenuImages:images)
        menu.delegate = self
        self.view.addSubview(menu)
    }

    // 画面が表示された後に呼び出される
    override internal func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        // マップにアートワークを表示する
        self.showSongInfo()
    }

    // メモリ警告が発生した場合の処理
    override internal func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    internal func PositionIconTapped(sender: UIButton){
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
    }

    /* ************************* */
    /* MKMapViewDelegate methods */
    /* ************************* */

    // 画像表示用にaddAnnotationから呼ばれる
    internal func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if !(annotation is CustomPointAnnotation) {
            return nil
        }
        
        let reuseId = "test"
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView.canShowCallout = true
        } else {
            anView.annotation = annotation
        }
        let deleteButton = UIButton(frame: CGRectMake(0,0,32,32))
        deleteButton.setImage(UIImage(named : "DeleteIcon"), forState: UIControlState.Normal)
        anView.rightCalloutAccessoryView = deleteButton

        // Set annotation-specific properties **AFTER**
        // the view is dequeued or created...
        let cpa = annotation as CustomPointAnnotation
        
        //アートワークサイズを32に固定
        let h = 32
        let w = 32
        if cpa.media.artwork != nil {
            //アートワークのデザインを角丸に設定
            anView.image = Toucan(image: cpa.media.artwork.imageWithSize(CGSize(width: w,height: h))).maskWithRoundedRect(cornerRadius: 10).image
        } else {
            
            println("no artwork")
            let Noimage = UIImage(named: "NoArtwork")? as UIImage!
            anView.image = Toucan(image: Noimage).maskWithRoundedRect(cornerRadius: 10).image
        }
        return anView
    }

    internal func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control != annotationView.rightCalloutAccessoryView {
            return
        }

        if !(annotationView.annotation is CustomPointAnnotation) {
            return
        }

        // alertViewの生成
        let message = "この地点に登録した曲を\n削除しますか？"
        let alertView = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)

        // 削除アクションの追加
        let deleteHandler = { (action: UIAlertAction!) -> Void in
            let cpa = annotationView.annotation as CustomPointAnnotation
            self.playRouteManager.delPlayRoute(cpa.media, center: annotationView.annotation.coordinate)
            mapView.removeAnnotation(annotationView.annotation)
            mapView.removeOverlay(cpa.overlay)
        }
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: deleteHandler)
        alertView.addAction(deleteAction)

        // キャンセルアクションの追加
        let cancelHandler = { (action:UIAlertAction!) -> Void in
            println("cancel")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: cancelHandler)
        alertView.addAction(cancelAction)

        // alertViewの表示
        presentViewController(alertView, animated: true, completion: nil)
    }

    internal func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        let renderer = MKCircleRenderer(overlay: overlay)
        // 淵の色
        renderer.strokeColor = UIColor.orangeColor().colorWithAlphaComponent(1)
        renderer.lineWidth = 1
        
        renderer.fillColor = UIColor.orangeColor().colorWithAlphaComponent(0.1)
        return renderer
    }

    /* ************************** */
    /* SphereMenuDelegate methods */
    /* ************************** */

    internal func sphereDidSelected(index: Int) {
        println("index = \(index)")
        // ひよコードです
        switch index {
        case 0:
            if state != 0 {
                println("Play")
                self.menuIcon = UIImage(named: "PlayIcon-on")
                self.playIcon = UIImage(named: "PlayIcon-on")
                self.recordIcon = UIImage(named: "RecordIcon-off")
                self.stopIcon = UIImage(named: "StopIcon-off")

                var images:[UIImage] = [self.playIcon!, self.recordIcon!, self.stopIcon!]
                var menu = SphereMenu(startPoint: CGPointMake(self.view.frame.width/2+120, 460), startImage: self.menuIcon!, submenuImages:images)
                menu.delegate = self
                self.view.addSubview(menu)

                self.backgroundRecController.stopUpdateLocation()
                self.backgroundPlayController.startUpdatingLocation()
                state = 0
            }
        case 1:
            if state != 1 {
                println("Record")
                self.menuIcon = UIImage(named: "RecordIcon-on")
                self.playIcon = UIImage(named: "PlayIcon-off")
                self.recordIcon = UIImage(named: "RecordIcon-on")
                self.stopIcon = UIImage(named: "StopIcon-off")

                var images:[UIImage] = [self.playIcon!, self.recordIcon!, self.stopIcon!]
                var menu = SphereMenu(startPoint: CGPointMake(self.view.frame.width/2+120, 460), startImage: self.menuIcon!, submenuImages:images)
                menu.delegate = self
                self.view.addSubview(menu)

                self.backgroundPlayController.stopUpdatingLocation()
                self.backgroundRecController.startUpdateLocation()
                state = 1
            }
        case 2:
            if state != 2 {
                println("Stop")
                self.menuIcon = UIImage(named: "StopIcon-on")
                self.playIcon = UIImage(named: "PlayIcon-off")
                self.recordIcon = UIImage(named: "RecordIcon-off")
                self.stopIcon = UIImage(named: "StopIcon-on")

                var images:[UIImage] = [self.playIcon!, self.recordIcon!, self.stopIcon!]
                var menu = SphereMenu(startPoint: CGPointMake(self.view.frame.width/2+120, 460), startImage: self.menuIcon!, submenuImages:images)
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

    /* ***************************** */
    /* BackgroundRecDelegate methods */
    /* ***************************** */

    internal func showSongInfo() {
        // TODO: 全てのPlayRoutesを一度に取得するのは重くなる可能性がある
        let playRoutes: [PlayRoute]! = self.playRouteManager.getPlayRoutes()

        if playRoutes == nil {
            return
        }

        for pr in playRoutes {
            var info: CustomPointAnnotation = CustomPointAnnotation()

            let latitude: CLLocationDegrees = pr.latitude
            let longitude: CLLocationDegrees = pr.longitude
            let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
            let circle = MKCircle(centerCoordinate: coordinate, radius: 40.0)

            info.coordinate = coordinate //表示位置
            info.title = pr.media.title // タイトル「曲名」
            info.subtitle = pr.media.artist // サブタイトル「アーティスト名」
            info.media = pr.media           //アートワーク用
            info.overlay = circle           //再生範囲用

            self.mapView.addAnnotation(info)
            self.mapView.addOverlay(circle)
        }
    }
}
