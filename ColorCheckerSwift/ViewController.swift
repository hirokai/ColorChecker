//
//  ViewController.swift
//  ColorCheckerSwift
//
//  Created by Hiroyuki Kai on 7/27/16.
//  Copyright © 2016 Hiroyuki Kai. All rights reserved.
//

import UIKit
import AVFoundation

class GraphView: UIView {
    var vs : [Float] = []
    var vs_count = 0
    var parent : ViewController!
    
    init(frame: CGRect, parent: ViewController) {
        super.init(frame: frame)
        self.vs = [0]
        self.vs_count = 0
        self.parent = parent
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func tr_x(v: Float, _ v0 : Float, _ duration : Float?) -> Float {
        var dur : Float
        if(duration == nil){
            dur = 10
        }else{
            dur = duration!
        }
        return (v-v0) / dur * Float(self.bounds.width) * 0.8
    }
    
    func transform_y(v : Float) -> Float {
        let vmin : Float = 0.0
        let vmax : Float = 30.0
        return (1-(v-vmin)/(vmax-vmin))*Float(self.bounds.height)
    }
    
    override func drawRect(rect: CGRect) {
        let h = rect.height
        let w = rect.width
        let color:UIColor = UIColor.blueColor()
        let path = CGPathCreateMutable()
        var x : Int = 0
        let vs = self.parent.vs_accum
        var y = vs[0]
        var xi_from : Int
        var xi_until : Int
        let ts = self.parent.times
        if(self.vs_count < 100){
            xi_from = 0
            xi_until = self.vs_count
        }else{
            xi_from = self.vs_count-100
            xi_until = self.vs_count
        }
        let dur : Float = 10
        CGPathMoveToPoint(path, nil, CGFloat(tr_x(ts[xi_from],ts[xi_from],dur)), CGFloat(y))
        for i in xi_from..<xi_until {
            CGPathAddLineToPoint(path, nil, CGFloat(self.tr_x(ts[i],ts[xi_from],dur)), CGFloat(self.transform_y(vs[i])))
        }
        let bpath:UIBezierPath = UIBezierPath(CGPath: path)
        bpath.lineWidth = 2
        color.set()
        bpath.stroke()
        
    }
}

class ROIView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let h = rect.height
        let w = rect.width
        let color:UIColor = UIColor.yellowColor()
        
        let drect = CGRect(x: (w * 0.5-w*0.1),y: (h * 0.5-w*0.1),width: (w*0.2),height: (w*0.2))
        let bpath:UIBezierPath = UIBezierPath(rect: drect)
        bpath.lineWidth = 2
        
        color.set()
        bpath.stroke()
    }
    
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var view2: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var smallView: UIImageView!
    @IBOutlet weak var colorView: UIView!
    var graphView: GraphView!
    @IBOutlet weak var graphViewBG: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.vs_accum = Array(count: 10000, repeatedValue: 0.0)
        self.times = Array(count: 10000, repeatedValue: 0.0)
        // Do any additional setup after loading the view, typically from a nib.
        self.configureCamera()
        let f = ROIView(frame: CGRectMake(0, 20, 375, 500))
        view.addSubview(f)
        graphView = GraphView(frame: CGRectMake(0, 370, 375, 150),parent: self)
        view.addSubview(graphView)
        mySession.startRunning()
        
    }
    
    var mySession : AVCaptureSession!
    var myDevice : AVCaptureDevice!
    var myImageOutput : AVCaptureStillImageOutput!

    var running : Bool = false
    var count = 0

    var vs_count = 0
    var times : [Float] = []
    var vs_accum : [Float] = []
    
    var prevCaptureTime : Double! = nil
    var initialTime : Double! = nil
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setCameraMode() {
        do {
            let d = self.myDevice
            try d.lockForConfiguration()
            d.activeVideoMinFrameDuration = CMTimeMake(1,10)
            d.activeVideoMaxFrameDuration = CMTimeMake(1,10)
            d.whiteBalanceMode = AVCaptureWhiteBalanceMode.Locked
            d.exposureMode = AVCaptureExposureMode.AutoExpose
            d.unlockForConfiguration()
        }catch{
        }
    }
    
    func configureCamera() -> Bool {
        mySession = AVCaptureSession()
        let devices = AVCaptureDevice.devices()
        for device in devices{
            if(device.position == AVCaptureDevicePosition.Back){
                myDevice = device as! AVCaptureDevice
            }
        }
        setCameraMode()
        
        let videoInput: AVCaptureInput!
        do {
            videoInput = try AVCaptureDeviceInput.init(device: myDevice!)
        }catch {
            videoInput = nil
        }
        
        mySession.addInput(videoInput)
        
        let previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session:mySession)
        previewLayer.frame = smallView.bounds
        smallView.layer.addSublayer(previewLayer)
        
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        mySession.addOutput(videoDataOutput)
        mySession.sessionPreset = AVCaptureSessionPreset640x480
        let cameraQueue = dispatch_queue_create("cameraQueue", nil)
        
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        
        return true
    }
    
    // FIXME: 間違っているっぽい。
    func rgb_to_lab(r2 : Float, _ g2 : Float, _ b2 : Float) -> [Float] {
        func f(t : Float) -> Float {
            if(t > 0.008856){
                return pow(t,0.3333)
            }else{
                return (pow(29.0/3.0,3)*t+16)/116// pow(29.0/6.0,2)/3.0*t + (4.0/29.0)
            }
        }
        
        let r : Float  = r2 / 256.0
        let g : Float  = g2 / 256.0
        let b : Float  = b2 / 256.0
        NSLog("rgb_to_lab")
        NSLog("%.0f %.0f %.0f",r2,g2,b2)
        NSLog("%.2f %.2f %.2f",r,g,b)
        
        //        let x : Float  = (r*0.490+g*0.310+b*0.200) * 256 // /0.17697
        //        let y : Float = (r*0.177+g*0.812+b*0.0601) * 256 // /0.17697
        //        let z : Float  = (r*0.000+g*0.010+b*0.990) * 256 // /0.17697
        let x : Float  = (r*2.7689+g*1.7517+b*1.1302)
        let y : Float = (r*1.0000+g*4.5907+b*0.072192)
        let z : Float  = (r*0.0601+g*0.0565+b*5.5943)
        NSLog("%.2f %.2f %.2f",x,y,z)
        
        let xn : Float  = 95.047
        let yn : Float = 100.0
        let zn : Float  = 108.883
        
        let l = 116.0*f(y/yn)-16
        let a = 500.0*(f(x/xn)-f(y/yn))
        let bb = 200.0*(f(y/yn)-f(z/zn))
        NSLog("%.2f %.2f %.2f",l,a,bb)
        return [l,a,bb]
    }
    
    
    // sampleBufferからCGImageを作成
    func captureImage(sampleBuffer:CMSampleBufferRef) -> (CGImageRef?,CGContext?) {
        // Sampling Bufferから画像を取得
        let imageBuffer:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // pixel buffer のベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let baseAddress:UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        //        NSLog("%d %d %d",bytesPerRow,width,height)
        
        // 色空間
        let colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        
        if(baseAddress == nil) {
            return (nil,nil)
        }
        
        let newContext:CGContextRef = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,
                                                            CGImageAlphaInfo.PremultipliedFirst.rawValue|CGBitmapInfo.ByteOrder32Little.rawValue)!
        let imageRefOpt = CGBitmapContextCreateImage(newContext)
        if(imageRefOpt == nil){
            NSLog("No image.")
        }
        
        //ここで計算
        let vs = self.measure(newContext)
        let lab = rgb_to_lab(vs[2],vs[1],vs[0])
        vs_accum[vs_count] = lab[0]
        NSLog("%.1f",lab[0])
        
        vs_count += 1
        times[vs_count] = Float(prevCaptureTime!-initialTime)
//        self.textField.text = (lab.map { String(format: "%.0f", $0)}).joinWithSeparator(",  ")
        self.textField.text = "L* = " + String(format: "%.0f", lab[0])
        dispatch_async(dispatch_get_main_queue()) {
            // Update the UI on the main thread.
            let c = UIColor(colorLiteralRed: vs[2]/255, green: vs[1]/255, blue: vs[0]/255, alpha: vs[3]/255)
            self.textField.layer.borderColor = c.CGColor
            self.textField.layer.borderWidth = 2
            self.colorView.backgroundColor = c
            self.graphView.vs = self.vs_accum
            self.graphView.vs_count = self.vs_count
            self.graphView.setNeedsDisplay()
            //            NSLog(c.description)
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        return (imageRefOpt,newContext)
    }
    
    //x,yが入れ替わっていることに注意（これで正しく動いている）
    private func measure(ctx: CGContextRef) -> [Float] {
        let x_offset : Int = 640/2-Int(480*0.1)
        let y_offset : Int = 480/2-Int(480*0.1)
        
        let w : Int = Int(480*0.1) // CGBitmapContextGetWidth(ctx)
        let h : Int = Int(480*0.1) // CGBitmapContextGetHeight(ctx)
        let dat: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(ctx))
        var accum : [Int] = [0,0,0,0]
        for x in x_offset..<(x_offset+w) {
            for y in y_offset..<(y_offset+h) {
                let bi = 4*(y*640+x)
                accum[0] += Int(dat[bi])
                accum[1] += Int(dat[bi+1])
                accum[2] += Int(dat[bi+2])
                accum[3] += Int(dat[bi+3])
            }
        }
        
        return accum.map{Float($0)/Float(w*h)}
    }
    
    @IBOutlet weak var textField: UILabel!
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        if(!running){
            return
        }
        let time = CACurrentMediaTime()
        //        if (prevCaptureTime == nil || time-prevCaptureTime >= 0.1) {
        prevCaptureTime = time
        dispatch_async(dispatch_get_main_queue(), {
            self.count += 1
            self.textField.text = String(self.count)
            let (cgImg,ctx) = self.captureImage(sampleBuffer)
            let cropped = CGImageCreateWithImageInRect(cgImg,CGRectMake(640/2-48,480/2-48,96,96))!  //x,yが入れ替わっていることに注意
            let resultImage = UIImage(CGImage: cropped, scale: 1.0, orientation: UIImageOrientation.Right)
            let image : UIImage? = resultImage
            self.view2.image = image
            
            
        })
        //        }
    }
    
    @IBAction func captureHandler(sender: AnyObject) {
        if(running){
            running = false
            button.setTitle("Start", forState: UIControlState.Normal)
            textField.text = ""
//x            mySession.stopRunning()
            self.vs_count = 0
            //            imageView.image = nil
        }else{
            setCameraMode()
            
            if(!mySession.running){
                mySession.startRunning()
            }
            running = true
            button.setTitle("Stop", forState: UIControlState.Normal)
            initialTime = CACurrentMediaTime()
            prevCaptureTime = initialTime
            
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.mySession.stopRunning()
        
    }
    
}

