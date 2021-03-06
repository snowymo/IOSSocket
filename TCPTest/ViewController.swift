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
import AVFoundation

class ViewController: UIViewController {
    
    //let host = "10.19.247.30"
    let port = 12345
    var tcpClient: TCPClient?
    var udpClient: UDPClient?
    
    var interval = 0.0001
    
    @IBOutlet weak var TextIPAddress: UITextField!
    var curProtocol = "udp"
    var curSending = false
    
    var motionManager = CMMotionManager()
    
    var songPlayer = AVAudioPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tcpClient = TCPClient(address: TextIPAddress.text!, port: Int32(port))
        udpClient = UDPClient(address: TextIPAddress.text!, port: Int32(port))
        prepareSongAndSession()
        songPlayer.setVolume(0, fadeDuration: 0)
        songPlayer.play()
    }
    @IBAction func IPValueChanged(_ sender: UITextField) {
        if self.curProtocol == "udp"{
            self.udpClient = UDPClient(address: sender.text!, port: Int32(self.port))
            
        }
        else{
            self.tcpClient = TCPClient(address: sender.text!, port: Int32(self.port))
        }
        print("Connected to host \(sender.text ?? "none")")
    }

    
    override func viewDidAppear(_ animated: Bool) {
        motionManager.gyroUpdateInterval = interval
        motionManager.startGyroUpdates(to: OperationQueue.current!) { (data, error) in
            if let mydata = data{
                //print( mydata.rotationRate)
                
                if self.curSending{
                    if self.curProtocol == "udp"{
                        if self.udpClient?.address != self.TextIPAddress.text{
                            self.udpClient = UDPClient(address: self.TextIPAddress.text!, port: Int32(self.port))
                        }
                        self.sendRequest(imu: mydata, using: self.udpClient!)
                    }
                    else{
                        if self.tcpClient?.address != self.TextIPAddress.text{
                            self.tcpClient = TCPClient(address: self.TextIPAddress.text!, port: Int32(self.port))
                        }
                        self.sendRequest(imu: mydata, using: self.tcpClient!)
                    }
                }
            }
        }
    }
    
    @IBAction func ProtocolChanged(_ sender: UISwitch) {
        if sender.isOn{
            // udp
            curProtocol = "udp"
        }else{
            curProtocol = "tcp"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func SendingChanged(_ sender: UISwitch) {
        if sender.isOn{
            // send
            curSending = true
        }
        else{
            curSending = false
        }
    }
    
//    @IBAction func SendClick(_ sender: Any) {
//        guard let client = tcpClient else { return }
//
//        switch client.connect(timeout: 10) {
//        case .success:
//            appendToTextField(string: "Connected to host \(client.address)")
//            if let response = sendRequest(string: "GET / HTTP/1.0\n\n", using: client) {
//                appendToTextField(string: "Response: \(response)")
//            }
//        case .failure(let error):
//            appendToTextField(string: String(describing: error))
//        }
//    }
    
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
    
    private func sendRequest(imu: CMGyroData, using client: TCPClient){
        appendToTextField(string: "Sending imu ... ")
        let arrayx = toByteArray(imu.rotationRate.x)
        let arrayy = toByteArray(imu.rotationRate.y)
        let arrayz = toByteArray(imu.rotationRate.z)
        let arrayt = toByteArray(imu.timestamp)
        let arrays = arrayx + arrayy + arrayz + arrayt
        
        switch client.send(data: arrays) {
        case .success:
            print("Sending successfully")
        case .failure(let error):
            print(String(describing: error))
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
    
    private func sendRequest(imu: CMGyroData, using client: UDPClient){
        appendToTextField(string: "Sending imu ... ")
        let arrayx = toByteArray(imu.rotationRate.x)
        let arrayy = toByteArray(imu.rotationRate.y)
        let arrayz = toByteArray(imu.rotationRate.z)
        let arrayt = toByteArray(imu.timestamp)
        let arrays = arrayx + arrayy + arrayz + arrayt
        
        switch client.send(data: arrays) {
        case .success:
            print("Sending successfully")
        case .failure(let error):
            print(String(describing: error))
        }
    }
    
//    private func readResponse(from client: UDPClient) -> String? {
//        guard let response = client.recv(1024*10).0 else { return nil }
//        //let response = client.recv(1024*10)
//
//        return String(bytes: response, encoding: .utf8)
//    }
    
    private func appendToTextField(string: String) {
        print(string)
        //textView.text = textView.text.appending("\n\(string)")
    }
    
    func prepareSongAndSession() {
        
        do {
            //7 - Insert the song from our Bundle into our AVAudioPlayer
            songPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "piano", ofType: "wav")!))
            //8 - Prepare the song to be played
            songPlayer.prepareToPlay()
            
            //9 - Create an audio session
            let audioSession = AVAudioSession.sharedInstance()
            do {
                //10 - Set our session category to playback music
                //try audioSession.setCategory(AVAudioSession.Category.playback)
                try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: [AVAudioSession.CategoryOptions.mixWithOthers])
                //11 -
            } catch let sessionError {
                
                print(sessionError)
            }
            //12 -
        } catch let songPlayerError {
            print(songPlayerError)
        }
    }
}

