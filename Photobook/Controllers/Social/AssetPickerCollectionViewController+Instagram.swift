//
//  AssetPickerCollectionViewController+Instagram.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 16/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import OAuthSwift

extension AssetPickerCollectionViewController {
    
    static func instagramAssetPicker() -> AssetPickerCollectionViewController{
        let assetPicker = photobookMainStoryboard.instantiateViewController(withIdentifier: "AssetPickerCollectionViewController") as! AssetPickerCollectionViewController
        assetPicker.album = InstagramAlbum()
        assetPicker.selectedAssetsManager = SelectedAssetsManager()
        assetPicker.prepareToHandleLogout(accountManager: InstagramClient.shared)
        InstagramClient.shared.authorizeURLHandler = assetPicker
        
        assetPicker.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: assetPicker, action: #selector(dismissPhotobook))
        
        return assetPicker
    }
    
}

extension AssetPickerCollectionViewController: OAuthSwiftURLHandlerType {
    
    func handle(_ url: URL) {
        self.popToLandingScreen()
    }
}
