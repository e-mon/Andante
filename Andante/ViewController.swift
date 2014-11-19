//
//  ViewController.swift
//  Andante
//
//  Created by admin on 2014/10/22.
//  Copyright (c) 2014年 sadp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func ModeChanged(sender: UISegmentedControl) {
        
        switch(sender.selectedSegmentIndex){
        // ここにモードのトグル処理を追加する
        case 0:
            println("play")
        case 1:
            println("record")
        case 2:
            println("stop")
        default:
            println("Error")
            
        }
    }

}

