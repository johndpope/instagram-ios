//
//  CameraController.swift
//  MyInstagram
//
//  Created by Jinwoo Kim on 26/04/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import AVFoundation

class CameraController: UIViewController {
    
    let output = AVCapturePhotoOutput()
    let customAnimationPresenter = CustomAnimationPresenter()
    let customAnimationDismisser = CustomAnimationDismisser()
    
    private let dismissButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "right_arrow_shadow").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    private let capturePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "capture_photo").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleCapturePhoto), for: .touchUpInside)
        return button
    }()
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK:- Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transitioningDelegate = self
        
        setupCaptureSession()
        
        setupHeadsUpDisplay()
    }
    
    deinit {
        print("CameraController \(#function)")
    }
    
    fileprivate func setupHeadsUpDisplay() {
        [dismissButton, capturePhotoButton].forEach {
            view.addSubview($0)
        }
        
        let guide = view.safeAreaLayoutGuide
        
        dismissButton.anchor(top: guide.topAnchor,
                             leading: nil,
                             bottom: nil,
                             trailing: guide.trailingAnchor,
                             padding: UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 12),
                             size: CGSize(width: 50, height: 50))
        
        capturePhotoButton.anchor(top: nil,
                                  leading: nil,
                                  bottom: guide.bottomAnchor,
                                  trailing: nil,
                                  padding: UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0),
                                  size: CGSize(width: 80, height: 80))
        capturePhotoButton.centerXInSuperview()
    }
    
    @objc fileprivate func handleDismiss() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func handleCapturePhoto() {
        let settings = AVCapturePhotoSettings()
        
        // do not execute camera capture for simulator
        #if (!arch(x86_64))
        guard let previewFormatType = settings.availablePreviewPhotoPixelFormatTypes.first else { return }
        
        settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewFormatType]
        
        output.capturePhoto(with: settings, delegate: self)
        #endif
    }
    
    fileprivate func setupCaptureSession() {
        let captureSession = AVCaptureSession()
        
        // 1. setup inputs
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch let err {
            print("Could not setup camera input:", err.localizedDescription)
        }
        
        // 2. setup outputs
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        // 3. setup output preview
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("Falied to capture photo: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        let previewImage = UIImage(data: imageData)
        
        let containerView = PreviewPhotoContainerView()
        containerView.previewImageView.image = previewImage
        view.addSubview(containerView)
        
        containerView.fillSuperview()
    }
}

// MARK:- Regarding UIViewControllerTransitioningDelegate
extension CameraController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return customAnimationPresenter
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return customAnimationDismisser
    }
}
