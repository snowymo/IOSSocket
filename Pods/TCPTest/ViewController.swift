//
//  ViewController.swift
//  TCPTest
//
//  Created by Zhenyi He on 1/29/19.
//

import UIKit
import SwiftSocket

class ViewController: UIViewController {

    let host = "apple.com"
    let port = 80
    var client: TCPClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func SendClick(_ sender: Any) {
    }
    
}

