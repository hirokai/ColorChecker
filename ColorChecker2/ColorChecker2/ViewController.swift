//
//  ViewController.swift
//  ColorChecker2
//
//  Created by Hiroyuki Kai on 7/29/16.
//  Copyright © 2016 Hiroyuki Kai. All rights reserved.
//

import UIKit
import AVFoundation

class ROIView : UIView {
    
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.vs_accum = Array(count: 10000, repeatedValue: 0.0)
        self.configureCamera()
        
    }
    
    var captureSession : AVCaptureSession
    var captureDevice : AVCaptureDevice
    
    func configureCamera() -> Bool {
        
        // セッションの作成.
        captureSession = AVCaptureSession()
        
        // デバイス一覧の取得.
        let devices = AVCaptureDevice.devices()
        
        // バックカメラをmyDeviceに格納.
        for device in devices{
            if(device.position == AVCaptureDevicePosition.Back){
                captureDevice = device as! AVCaptureDevice
            }
        }
        
        // バックカメラからVideoInputを取得.
        let videoInput: AVCaptureInput!
        
        do{
            try self.myDevice.lockForConfiguration()
            self.myDevice.activeVideoMinFrameDuration = CMTimeMake(1,5);
            self.myDevice.activeVideoMaxFrameDuration = CMTimeMake(1,5);
            self.myDevice.unlockForConfiguration()
        } catch {
            
        }
        
        do {
            videoInput = try AVCaptureDeviceInput.init(device: myDevice!)
        }catch{
            videoInput = nil
        }
        
        // セッションに追加.
        mySession.addInput(videoInput)
        
        // 出力先を生成.
        //        myImageOutput = AVCaptureStillImageOutput()
        
        
        let previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session:mySession)
        previewLayer.frame = smallView.bounds
        smallView.layer.addSublayer(previewLayer)
        
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        // セッションに追加.
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        mySession.addOutput(videoDataOutput)
        mySession.sessionPreset = AVCaptureSessionPreset640x480
        let cameraQueue = dispatch_queue_create("cameraQueue", nil)
        
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        
        videoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        
        
        /*
         // 画像を表示するレイヤーを生成.
         myVideoLayer.frame = self.view.bounds
         myVideoLayer.videoGravity = AVLayerVideoGravityResizeAspect
         
         // Viewに追加.
         //        self.view.layer.addSublayer(myVideoLayer)
         
         */
        
        NSLog("hey\n")
        
        return true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

