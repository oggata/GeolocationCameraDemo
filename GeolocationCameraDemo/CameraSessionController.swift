//
//  CameraSessionController.swift
//  GeolocationCameraDemo
//
//  Created by Fumitoshi Ogata on 2014/07/30.
//  Copyright (c) 2014年 Fumitoshi Ogata. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreImage
import AssetsLibrary
import CoreLocation
import ImageIO

@objc protocol CameraSessionControllerDelegate {
    @optional func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!)
}

class CameraSessionController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var session: AVCaptureSession!
    var sessionQueue: dispatch_queue_t!
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDeviceOutput: AVCaptureVideoDataOutput!
    var stillImageOutput: AVCaptureStillImageOutput!
    var runtimeErrorHandlingObserver: AnyObject?
    
    var sessionDelegate: CameraSessionControllerDelegate?
        
    class func deviceWithMediaType(mediaType: NSString, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        var devices: NSArray = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice: AVCaptureDevice = devices.firstObject as AVCaptureDevice
        
        for object:AnyObject in devices {
            let device = object as AVCaptureDevice
            if (device.position == position) {
                captureDevice = device
                break
            }
        }
        
        return captureDevice
    }
        
    init() {
        super.init();
        
        //セッションを初期化
        self.session = AVCaptureSession()
        
        self.authorizeCamera();
        
        self.sessionQueue = dispatch_queue_create("CameraSessionController Session", DISPATCH_QUEUE_SERIAL)
        
        //バックグラウンド処理で実行する
        dispatch_async(self.sessionQueue, {
            self.session.beginConfiguration()
            self.addVideoInput()
            self.addVideoOutput()
            self.addStillImageOutput()
            self.session.commitConfiguration()
            })
    }
        
    func authorizeCamera() {
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {
            (granted: Bool) -> Void in
            // If permission hasn't been granted, notify the user.
            if !granted {
                dispatch_async(dispatch_get_main_queue(), {
                    UIAlertView(
                        title: "Could not use camera!",
                        message: "This application does not have permission to use camera. Please update your privacy settings.",
                        delegate: self,
                        cancelButtonTitle: "OK").show()
                    })
            }
            });
    }
    
    func addVideoInput() -> Bool {
        var success: Bool = false
        var error: NSError?
        //1)カメラでバイスの初期化を行う
        var videoDevice: AVCaptureDevice = CameraSessionController.deviceWithMediaType(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
        //2)入力の初期化を行う
        self.videoDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &error) as AVCaptureDeviceInput;
        if !error {
            //3)セッションの初期化を行う
            if self.session.canAddInput(self.videoDeviceInput) {
                self.session.addInput(self.videoDeviceInput)
                success = true
            }
        }
        
        return success
    }
    
    
    /*
    ==AVCaptureOutput 出力の初期化==
    AVCaptureStillImageOutput : 静止画
    AVCaptureMoveiFileOutput  : 動画
    AVCaptureVideoDataOutput  : ビデオデータ
    AVCaptureAudioDataOutput  : 音声データ
    AVCaptureMetadataOutput   : 顔、QRコード
    AVMutableComposition      : 動画の再編成
    AVVideoCompositionCoreAnimationTool : 画像との合成
    AVAssetExportSession      : 動画変換
    AVAssetWrite              : フレームから動画構築
    */
    func addVideoOutput() {

        self.videoDeviceOutput = AVCaptureVideoDataOutput()
        self.videoDeviceOutput.alwaysDiscardsLateVideoFrames = true
        self.videoDeviceOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        
        //セッションの初期化を行う
        if self.session.canAddOutput(self.videoDeviceOutput) {
            self.session.addOutput(self.videoDeviceOutput)
        }
    }
    
    func addStillImageOutput() {

        self.stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
        //セッションの初期化を行う
        if self.session.canAddOutput(self.stillImageOutput) {
            self.session.addOutput(self.stillImageOutput)
        }
    }
    
    func startCamera() {
        dispatch_async(self.sessionQueue, {
            var weakSelf: CameraSessionController? = self
            self.runtimeErrorHandlingObserver = NSNotificationCenter.defaultCenter().addObserverForName(AVCaptureSessionRuntimeErrorNotification, object: self.sessionQueue, queue: nil, usingBlock: {
                (note: NSNotification!) -> Void in
                
                let strongSelf: CameraSessionController = weakSelf!
                
                dispatch_async(strongSelf.sessionQueue, {
                    strongSelf.session.startRunning()
                    })
                })
            //セッションをスタートさせる
            self.session.startRunning()
            })
    }
    
    func teardownCamera() {
        dispatch_async(self.sessionQueue, {
            self.session.stopRunning()
            NSNotificationCenter.defaultCenter().removeObserver(self.runtimeErrorHandlingObserver)
            })
    }

    func compositionImageAndSavePhoto(){
        //非同期で静止画をキャプチャ
        dispatch_async(self.sessionQueue, {
            //キャプチャを撮る＋自動的にシャッター音が鳴る
            self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo), completionHandler: {
                (imageDataSampleBuffer: CMSampleBuffer?, error: NSError?) -> Void in
                
                //CoreMediaのままではUIKitで使いにくいので変換
                var imageData: NSData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer?)
                var image: UIImage = UIImage(data: imageData)

                /*
                //UIGraphicsここから開始
                UIGraphicsBeginImageContext(image.size)
                //(UIImageのdrawInRectメソッドを使うと上下逆さまにならない)<->CGContextDrawImageだと逆になる
                image.drawInRect(CGRectMake(0,0,image.size.width,image.size.height))
                
                //コンテキストを作成
                var drawCtxt = UIGraphicsGetCurrentContext()
                
                //合成する画像を用意する
                var targetImg  = UIImage(named:"penguin1.png")
                var targetRect = CGRectMake(0,0,145*3,195*3)
                //CGContextDrawImage(drawCtxt,targetRect,targetImg.CGImage)
                targetImg.drawInRect(targetRect)

                //イメージを合成する
                var drawedImage = UIGraphicsGetImageFromCurrentImageContext()
                
                //UIGraphicsここで終了
                UIGraphicsEndImageContext()
                
                //結果を詰める
                image = drawedImage
                */
                
                //カメラロールに画像を保存する
                //(このメソッドを使用するとメタデータは保存されない)
                //UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);

                //GPSにWaikikiBeachの座標をセットする
                var gps = NSMutableDictionary()
                gps.setObject(1111,forKey:kCGImagePropertyGPSDateStamp)
                gps.setObject(1111,forKey:kCGImagePropertyGPSTimeStamp)
                gps.setObject("N",forKey:kCGImagePropertyGPSLatitudeRef)
                gps.setObject(21.275468,forKey:kCGImagePropertyGPSLatitude)
                gps.setObject("W",forKey:kCGImagePropertyGPSLongitudeRef)
                gps.setObject(157.825294,forKey:kCGImagePropertyGPSLongitude)
                gps.setObject(0,forKey:kCGImagePropertyGPSAltitudeRef)
                gps.setObject(0,forKey:kCGImagePropertyGPSAltitude)

                //EXIF情報を作成する
                var exif = NSMutableDictionary() 
                
                //写真のコメントをセットする
                exif.setObject("I love Waikiki Beach",forKey:kCGImagePropertyExifUserComment)
                
                //GPS情報をセットする
                exif.setObject(gps,forKey:kCGImagePropertyGPSDictionary);
                
                var metaData = NSMutableDictionary()
                metaData.setObject(exif,forKey:kCGImagePropertyExifDictionary)

                //メタデータを保存するためにはAssetsLibraryを使用する
                var library : ALAssetsLibrary = ALAssetsLibrary()

                //writeImageDataToSavedPhotosAlbum : UIImage
                library.writeImageToSavedPhotosAlbum(image.CGImage,metadata: metaData, completionBlock:{
                    (assetURL: NSURL!, error: NSError!) -> Void in
                    println("EDQueueResultSuccess")
                })
              
            })
        })
    }
    
    /*
    AVCaptureVideoDataOutputクラスは、キャプチャしたデータをそのままアプリに渡してくれる。
    そのデータを受け取るために、デリゲートメソッドが用意されている。
    */	
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        self.sessionDelegate?.cameraSessionDidOutputSampleBuffer?(sampleBuffer)
    }
    
}