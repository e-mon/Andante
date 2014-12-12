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


private class PlayRouteAnnotation: MKPointAnnotation {
    private var media: MPMediaItem!
    private var overlay: MKOverlay!

    init(playRoute: PlayRoute) {
        super.init()

        self.coordinate = CLLocationCoordinate2DMake(playRoute.latitude, playRoute.longitude)
        self.overlay = MKCircle(centerCoordinate: self.coordinate, radius: 40.0)

        self.media = playRoute.media
        self.title = self.media.title
        self.subtitle = self.media.artist
    }
}


private class PlayRouteAnnotationView: MKAnnotationView {
    private init!(annotation: PlayRouteAnnotation) {
        super.init(annotation: annotation, reuseIdentifier: "PlayRouteAnnotationView")

        self.canShowCallout = true
        let deleteButton = UIButton(frame: CGRectMake(0,0,32,32))
        deleteButton.setImage(UIImage(named : "DeleteIcon"), forState: UIControlState.Normal)
        self.rightCalloutAccessoryView = deleteButton
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setAnnotation(annotation: PlayRouteAnnotation) {
        self.annotation = annotation
        let image = annotation.media.artwork?.imageWithSize(CGSize(width: 32, height: 32)) ?? UIImage(named: "NoArtwork")
        self.image = Toucan(image: image!).maskWithRoundedRect(cornerRadius: 10).image
    }
}


private enum AppMode: Int {
    case Playing = 0
    case Recording = 1
    case Stopped = 2
}


class MapViewController: UIViewController, MKMapViewDelegate, SphereMenuDelegate, BackgroundRecDelegate {
    @IBOutlet private weak var mapView: MKMapView!

    // FIXME: 理想的にはSphereMenuもStoryboadで配置してOutletにしたい
    private var modeMenu: SphereMenu!

    private let backgroundPlayController = BackgroundPlayController()
    private let backgroundRecController = BackgroundRecController()
    private let playRouteManager = PlayRouteManager()

    private lazy var uiImages: [String: UIImage] = {
        let images = [
            "StopIcon-on": UIImage(named: "StopIcon-on")!,
            "StopIcon-off": UIImage(named: "StopIcon-off")!,
            "PlayIcon-on": UIImage(named: "PlayIcon-on")!,
            "PlayIcon-off": UIImage(named: "PlayIcon-off")!,
            "RecordIcon-on": UIImage(named: "RecordIcon-on")!,
            "RecordIcon-off": UIImage(named: "RecordIcon-off")!
        ]
        return images
    }()

    // FIXME: 理想的にはcurrentPositionButtonもStoryboadで配置してOutletにしたい
    private lazy var currentPositionButton: UIButton! = {
        let button = UIButton()
        button.tag = 4
        button.frame = CGRectMake(0, 0, 128, 128)
        button.layer.position = CGPoint(x: self.view.frame.width/2 + 120, y: 530)
        button.setImage(UIImage(named: "PositionIcon"), forState: .Normal)
        button.addTarget(self, action: "currentPositionButtonTapped:", forControlEvents: .TouchUpInside)
        return button
    }()

    private var currentMode = AppMode.Stopped

    override internal func viewDidLoad() {
        super.viewDidLoad()

        let locationManager = CLLocationManager()
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.NotDetermined {
            locationManager.requestAlwaysAuthorization();
        }

        self.backgroundRecController.delegate = self
        self.mapView.delegate = self

        self.mapView.showsUserLocation = true
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)

        self.view.addSubview(self.mapView)
        self.view.sendSubviewToBack(self.mapView)

        self.view.addSubview(self.currentPositionButton)

        let start: UIImage! = self.uiImages["StopIcon-on"]
        let images: [UIImage] = [self.uiImages["PlayIcon-off"]!, self.uiImages["RecordIcon-off"]!, self.uiImages["StopIcon-on"]!]
        self.addModeMenu(startImage: start, submenuImages: images)
    }

    override internal func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)

        self.showSongInfo()
    }

    override internal func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    internal func currentPositionButtonTapped(sender: UIButton){
        self.mapView.setUserTrackingMode(MKUserTrackingMode.Follow, animated: true)
    }

    private func addModeMenu(#startImage: UIImage, submenuImages: [UIImage]) {
        // FIXME: モード切り替えのたびにSphereMenuを再生成してしまっている
        //        SphereMenuの仕様上、アイコン画像をうまいこと変えるのが難しいのでこうなっているが
        //        メモリ管理上は良くないし、何度も切り替えるとボタンに微妙な影がつくので、どうにかしたい
        let point = CGPointMake(self.view.frame.width/2 + 120, 460)
        self.modeMenu = SphereMenu(startPoint: point, startImage: startImage, submenuImages: submenuImages)
        self.modeMenu.delegate = self
        self.view.addSubview(self.modeMenu)
    }

    private func showPlayRouteDeletionAlert(removeFromMapView mapView: MKMapView, removeAnnotation annotation: PlayRouteAnnotation) {
        let message = "この地点に登録した曲を\n削除しますか？"
        let controller = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)

        let deleteHandler = { (action: UIAlertAction!) -> Void in
            self.playRouteManager.delPlayRoute(annotation.media, center: annotation.coordinate)
            mapView.removeAnnotation(annotation)
            mapView.removeOverlay(annotation.overlay)
        }
        let deleteAction = UIAlertAction(title: "削除", style: UIAlertActionStyle.Destructive, handler: deleteHandler)
        controller.addAction(deleteAction)

        let cancelHandler = { (action:UIAlertAction!) -> Void in
            return
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: UIAlertActionStyle.Cancel, handler: cancelHandler)
        controller.addAction(cancelAction)

        presentViewController(controller, animated: true, completion: nil)
    }

    /* ************************* */
    /* MKMapViewDelegate methods */
    /* ************************* */

    internal func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // COMMENT: 将来的に他のannotationにも対応できるよう、MKAnnotationのサブクラスによって場合分けする
        if annotation is PlayRouteAnnotation {
            let custom = annotation as PlayRouteAnnotation
            let view = (mapView.dequeueReusableAnnotationViewWithIdentifier("PlayRouteAnnotationView") ?? PlayRouteAnnotationView(annotation: custom)) as PlayRouteAnnotationView
            view.setAnnotation(custom)
            return view
        }
        return nil
    }

    internal func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // COMMENT: 将来的に他のannotationにも対応できるよう、MKAnnotationのサブクラスによって場合分けする
        if annotationView is PlayRouteAnnotationView {
            if control == annotationView.rightCalloutAccessoryView {
                let annotation = annotationView.annotation as PlayRouteAnnotation
                self.showPlayRouteDeletionAlert(removeFromMapView: mapView, removeAnnotation: annotation)
            }
        }
    }

    internal func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        // FIXME: 本来はPlayRouteAnnotation専用のMKOverlayのサブクラスを作って場合分けすべき
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.lineWidth = 1
            renderer.strokeColor = UIColor.orangeColor().colorWithAlphaComponent(1)
            renderer.fillColor = UIColor.orangeColor().colorWithAlphaComponent(0.1)
            return renderer
        }
        return nil
    }

    /* ************************** */
    /* SphereMenuDelegate methods */
    /* ************************** */

    internal func sphereDidSelected(index: Int) {
        let newMode = AppMode(rawValue: index)
        if newMode == nil || newMode == currentMode {
            return
        }

        switch newMode! {
        case .Playing:
            let start: UIImage = self.uiImages["PlayIcon-on"]!
            let images: [UIImage] = [self.uiImages["PlayIcon-on"]!, self.uiImages["RecordIcon-off"]!, self.uiImages["StopIcon-off"]!]
            self.addModeMenu(startImage: start, submenuImages: images)

            self.backgroundRecController.stopUpdateLocation()
            self.backgroundPlayController.startUpdatingLocation()
            self.currentMode = .Playing

        case .Recording:
            let start: UIImage = self.uiImages["RecordIcon-on"]!
            let images: [UIImage] = [self.uiImages["PlayIcon-off"]!, self.uiImages["RecordIcon-on"]!, self.uiImages["StopIcon-off"]!]
            self.addModeMenu(startImage: start, submenuImages: images)

            self.backgroundPlayController.stopUpdatingLocation()
            self.backgroundRecController.startUpdateLocation()
            self.currentMode = .Recording

        case .Stopped:
            let start: UIImage = self.uiImages["StopIcon-on"]!
            let images: [UIImage] = [self.uiImages["PlayIcon-off"]!, self.uiImages["RecordIcon-off"]!, self.uiImages["StopIcon-on"]!]
            self.addModeMenu(startImage: start, submenuImages: images)

            self.backgroundPlayController.stopUpdatingLocation()
            self.backgroundRecController.stopUpdateLocation()
            self.currentMode = .Stopped
        }
    }

    /* ***************************** */
    /* BackgroundRecDelegate methods */
    /* ***************************** */

    internal func showSongInfo() {
        // FIXME: 全てのPlayRoutesを一度に取得するのは重くなる可能性がある
        let playRoutes: [PlayRoute]! = self.playRouteManager.getPlayRoutes()

        if playRoutes == nil {
            return
        }

        for playRoute in playRoutes {
            let annotation = PlayRouteAnnotation(playRoute: playRoute)
            self.mapView.addAnnotation(annotation)
            self.mapView.addOverlay(annotation.overlay)
        }
    }
}
