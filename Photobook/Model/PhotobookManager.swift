//
//  PhotobookManager.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Shared manager for the photo book UI
class PhotobookManager: NSObject {
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    static func setupPayments() {
        PaymentAuthorizationManager.applePayPayTo = "Kite.ly (via HD Photobooks)"
        PaymentAuthorizationManager.applePayMerchantId = "merchant.ly.kite.sdk"
        KiteAPIClient.shared.apiKey = "78b798ff366815c833dfa848654aba43b71a883a"
    }
    
    static func rootViewControllerForCurrentState() -> UIViewController {
        let tabBarController = photobookMainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        configureTabBarController(tabBarController)
        return tabBarController
    }
    
    static func configureTabBarController(_ tabBarController: UITabBarController) {
        
        // Browse
        // Set the albumManager to the AlbumsCollectionViewController
        if let albumViewController = (tabBarController.viewControllers?[Tab.browse.rawValue] as? UINavigationController)?.topViewController as? AlbumsCollectionViewController {
            albumViewController.albumManager = PhotosAlbumManager()
            albumViewController.addDismissButton()
        }
        
        // Stories
        // If there are no stories, remove the stories tab
        StoriesManager.shared.loadTopStories(completionHandler: {
            if StoriesManager.shared.stories.isEmpty {
                tabBarController.viewControllers?.remove(at: Tab.stories.rawValue)
            }
        })
        
        // Load the products here, so that the user avoids a loading screen on PhotobookViewController
        ProductManager.shared.initialise(completion: nil)
    }
}
