//
//  ViewController.swift
//  TCPTest
//
//  Created by Zhenyi He on 1/29/19.
//  Copyright © 2019 Zhenyi He. All rights reserved.
//

import UIKit
import SwiftSocket
import CoreMotion


class ViewController: UIViewController {
    
    let host = "10.19.247.30"
    let port = 12345
    var client: TCPClient?
    var udpClient: UDPClient?
    
    var interval = 0.0001
    
    var motionManager = CMMotionManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        client = TCPClient(address: host, port: Int32(port))
        udpClient = UDPClient(address: host, port: Int32(port))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        motionManager.gyroUpdateInterval = interval
        motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
            if let mydata = data{
                print( mydata.rotationRate)
                
                self.appendToTextField(string: "Connected to host \(self.udpClient!.address)")
                if let response = self.sendRequest(imu: mydata, using: self.udpClient!) {
                    self.appendToTextField(string: "Response: \(response)")
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func UDPSend(_ sender: Any) {
        guard let udpClient = udpClient else { return }

            appendToTextField(string: "Connected to host \(udpClient.address)")
            if let response = sendRequest(string: "GET / HTTP/1.0\n\n", using: udpClient) {
                appendToTextField(string: "Response: \(response)")
            }
    }
    
    @IBAction func SendClick(_ sender: Any) {
        guard let client = client else { return }
        
        switch client.connect(timeout: 10) {
        case .success:
            appendToTextField(string: "Connected to host \(client.address)")
            if let response = sendRequest(string: "GET / HTTP/1.0\n\n", using: client) {
                appendToTextField(string: "Response: \(response)")
            }
        case .failure(let error):
            appendToTextField(string: String(describing: error))
        }
    }
    
    private func sendRequest(string: String, using client: TCPClient) -> String? {
        appendToTextField(string: "Sending data ... ")
        
        switch client.send(string: string) {
        case .success:
            return readResponse(from: client)
        case .failure(let error):
            appendToTextField(string: String(describing: error))
            return nil
        }
    }
    
    private func readResponse(from client: TCPClient) -> String? {
        guard let response = client.read(1024*10) else { return nil }
        
        return String(bytes: response, encoding: .utf8)
    }
    
    private func sendRequest(string: String, using client: UDPClient) -> String? {
        appendToTextField(string: "Sending data ... ")
        
        switch client.send(string: string) {
        case .success:
            appendToTextField(string: "Sending successfully")
            return nil
        case .failure(let error):
            appendToTextField(string: String(describing: error))
            return nil
        }
    }
    
    func toByteArray<T>(_ value: T) -> [UInt8] {
        var value = value
        return withUnsafeBytes(of: &value) { Array($0) }
    }
    
    private func sendRequest(imu: CMGyroData, using client: UDPClient) -> String? {
        appendToTextField(string: "Sending imu ... ")
        let arrayx = toByteArray(imu.rotationRate.x)
        let arrayy = toByteArray(imu.rotationRate.y)
        let arrayz = toByteArray(imu.rotationRate.z)
        let arrayt = toByteArray(imu.timestamp)
        let arrays = arrayx + arrayy + arrayz + arrayt
        
        switch client.send(data: arrays) {
        case .success:
            appendToTextField(string: "Sending successfully")
            return nil
        case .failure(let error):
            appendToTextField(string: String(describing: error))
            return nil
        }
    }
    
    private func readResponse(from client: UDPClient) -> String? {
        guard let response = client.recv(1024*10).0 else { return nil }
        //let response = client.recv(1024*10)
        
        return String(bytes: response, encoding: .utf8)
    }
    
    private func appendToTextField(string: String) {
        print(string)
        //textView.text = textView.text.appending("\n\(string)")
    }
    
}

