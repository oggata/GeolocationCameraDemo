//
//  ViewController.swift
//  GeolocationCameraDemo
//
//  Created by Fumitoshi Ogata on 2014/07/30.
//  Copyright (c) 2014年 Fumitoshi Ogata. All rights reserved.
//

import UIKit
import CoreMedia
import AVFoundation

class ViewController: UIViewController, CameraSessionControllerDelegate {
    
    var mLocationController     : LocationController!
    var cameraSessionController : CameraSessionController!
    var previewLayer            : AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        //カメラをコントロールする
        self.cameraSessionController = CameraSessionController()
        self.cameraSessionController.sessionDelegate = self
        self.setupPreviewLayer()
        
        //位置情報を取得する
        self.mLocationController = LocationController()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.cameraSessionController.startCamera()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraSessionController.teardownCamera()
    }
    
    func setupPreviewLayer() {
        //プレビュー用の画面を作成
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraSessionController.session)
        
        //縦と横の短い方にサイズを合わせる
        var minSize: Float = min(self.view.bounds.size.width, self.view.bounds.size.height)
        //var bounds: CGRect = CGRectMake(0.0, 0.0, minSize, minSize)
        var bounds: CGRect = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)
        self.previewLayer.bounds = bounds
        //中心に位置を置く
        self.previewLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds))
        
        /*
        重心設定 videoGravity
        AVLayerVideoGravityResizeAspect： アスペクト比維持
        AVLayerVideoGravityResizeAspectFill：アスペクト比固定で画面全域
        AVLayerVideoGravityResize：アスペクト比変化で画面全域
        */
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        
        //ツールバーを作成
        var toolBar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        toolBar.barStyle = UIBarStyle.Default
        toolBar.barTintColor = UIColor.whiteColor()
        //self.view.addSubview(toolBar)
        
        //ボタンの生成
        var button = UIButton(frame: CGRectMake(260, 30, 50, 50))
        button.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        button.addTarget(self, action: "pushBtn:", forControlEvents:.TouchUpInside)
        self.view.addSubview(button) 
    }

    //ボタン押下時の処理
    func pushBtn(sender: UIButton){       
        println("button push!")
        //AudioServicesPlaySystemSound(1108);
        self.cameraSessionController.compositionImageAndSavePhoto();
    }

    func cameraSessionDidOutputSampleBuffer(sampleBuffer: CMSampleBuffer!) {
        // Any frame processing could be done here.
    }
    
}