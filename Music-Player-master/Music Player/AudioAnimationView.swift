//
//  AudioAnimationView.swift
//  CleanAudio
//
//  Created by Mostafizur Rahman on 1/1/19.
//  Copyright © 2019 UBUNIFU Inc. All rights reserved.
//

import UIKit

class AudioAnimationView: UIView {

    
   
    var imageContext:CGContext!
    var imagePointer:UnsafeMutablePointer<UInt32>!
    
    var imageWidth:Int = 0
    var imageHeight:Int = 0
    var totalPixels:Int = 0
    var originX:Int  = 0
    var drawRect:CGRect = .zero
    
    //must be set from main(UI) thread
    var barHeight:Int = 0 {
        didSet{
            
            self.setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    fileprivate func configure() {
    
        var pixHeight:CGFloat = 30
        for layout in self.constraints {
            if let idf = layout.identifier,
                idf.elementsEqual("HL") {
                pixHeight = layout.constant
            }
        }
        
        self.imageWidth = Int(UIScreen.main.nativeBounds.width * 0.9)
        self.imageHeight = Int(pixHeight * UIScreen.main.scale)
        self.drawRect.size.width = CGFloat(self.imageWidth)
        self.drawRect.size.height = CGFloat(self.imageHeight)
        self.drawRect.origin.x = -6.0
        self.originX = self.imageWidth - 4
        self.totalPixels = self.imageHeight * self.imageWidth
        let bitsPerComponent = 8
        let bytesPerRow = 4 * self.imageWidth
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue |
            CGImageAlphaInfo.premultipliedFirst.rawValue
        self.imageContext = CGContext(data: nil,
                                      width: self.imageWidth ,
                                      height: self.imageHeight ,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo)
        if let __data = self.imageContext.data {
            self.imagePointer = __data.bindMemory(to: UInt32.self, capacity: self.totalPixels * 4)
        }
    }
    
    var shouldClearContext:Bool = false {
        didSet {
            if self.shouldClearContext {
                var index = 0
                while index < self.totalPixels {
                    self.imagePointer.advanced(by: index).pointee = 0
                    index += 1
                }
                self.imageContext.clear(self.bounds)
                self.setNeedsDisplay()
            }
        }
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        if self.shouldClearContext {
            self.imageContext.clear(rect)
        }
        if let __cg_image = self.imageContext.makeImage() {
            if !self.shouldClearContext {
                let originY = Int(Float(self.imageHeight) / 2.0 - Float(self.barHeight) / 2.0)
                for x in self.originX...self.originX + 1 {
                    for y in 0...self.imageHeight {
                        let index = (self.imageWidth * y) + x
                        if index < self.totalPixels{
                            let pointer = self.imagePointer.advanced(by: index )
                            
                            if originY < y && y < originY + self.barHeight {
                                pointer.pointee = 1671168000
                            } else {
                                pointer.pointee = 0
                            }
                        }
                    }
                }
            }
            self.shouldClearContext = false
            self.imageContext.clear(self.drawRect)
            self.imageContext.draw(__cg_image, in: self.drawRect)
            if let __out_image = self.imageContext.makeImage() {
                let uiimage = UIImage(cgImage: __out_image)
                uiimage.draw(in: rect)
            }
        }
    }
}
