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

    @IBAction func PlayButton(sender: UIBarButtonItem) {
        println("Play")
    }

    @IBAction func RecordButton(sender: UIBarButtonItem) {
        println("Record")
    }
    
    @IBAction func StopButton(sender: UIBarButtonItem) {
        println("Stop")
    }
    
    @IBAction func CurrentPositionButton(sender: UIBarButtonItem) {
        println("Current Position")
    }
    
}

