//
//  PhotoBookNavigationBar.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookNavigationBar: UINavigationBar {
    
    private static let contentHeight: CGFloat = 44.0
    private static let promptHeight: CGFloat = 34.0
    
    var hasAddedBlur = false
    var effectView: UIVisualEffectView!
    
    var willShowPrompt = false {
        didSet {
            if #available(iOS 11.0, *) {
                prefersLargeTitles = !willShowPrompt
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !hasAddedBlur {
            hasAddedBlur = true
            
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            let effectViewHeight = willShowPrompt ? PhotoBookNavigationBar.contentHeight + PhotoBookNavigationBar.promptHeight : PhotoBookNavigationBar.contentHeight + statusBarHeight
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            effectView.frame = CGRect(x: 0.0, y: 0.0, width: bounds.width, height: effectViewHeight)
            effectView.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
            insertSubview(effectView, at: 0)
        }
        sendSubview(toBack: effectView)
    }
    
    func setup() {
        barTintColor = .white
        
        if #available(iOS 11.0, *) {
            prefersLargeTitles = true
        }
        
        setBackgroundImage(UIImage(color: .clear), for: .default)
        shadowImage = UIImage()
    }
    
}
