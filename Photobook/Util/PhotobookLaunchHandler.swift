//
//  AppLaunchHandler.swift
//  Photobook
//
//  Created by Julian Gruber on 19/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

let photobookBundle = Bundle(for: Photobook.self)
let photobookMainStoryboard =  UIStoryboard(name: "Main", bundle: photobookBundle)

@objc public class PhotobookLaunchHandler: NSObject {
    
    @objc public enum Environment: Int {
        case test
        case live
    }
    
    @objc public static let orderWasCreatedNotificationName = Notification.Name("ly.kite.sdk.orderWasCreated")
    @objc public static let orderWasSuccessfulNotificationName = Notification.Name("ly.kite.sdk.orderWasSuccessful")
    @objc public static var environment: Environment = .live
    
    enum Tab: Int {
        case stories
        case browse
        case instagram
        case facebook
    }
    
    static func getInitialViewController() -> UIViewController {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as! UITabBarController
        
        if IntroViewController.userHasDismissed && !OrderProcessingManager.shared.isProcessingOrder {
            configureTabBarController(tabBarController)
            return tabBarController
        }
        
        let rootNavigationController = UINavigationController(navigationBarClass: PhotobookNavigationBar.self, toolbarClass: nil)
        rootNavigationController.isNavigationBarHidden = true
        if #available(iOS 11.0, *) {
            rootNavigationController.navigationBar.prefersLargeTitles = false // large titles on nav vc containing other nav vcs causes issues
        }
        
        if !IntroViewController.userHasDismissed {
            let introViewController = storyboard.instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
            introViewController.dismissClosure = {
                configureTabBarController(tabBarController)
                introViewController.proceedToTabBarController()
            }
            rootNavigationController.viewControllers = [introViewController]
            
        } else if OrderProcessingManager.shared.isProcessingOrder {
            //show receipt screen to prevent user from ordering another photobook
            let receiptViewController = storyboard.instantiateViewController(withIdentifier: "ReceiptTableViewController") as! ReceiptTableViewController
            receiptViewController.order = OrderManager.shared.loadBasketOrder()
            receiptViewController.dismissClosure = {
                configureTabBarController(tabBarController)
                rootNavigationController.isNavigationBarHidden = true
                receiptViewController.proceedToTabBarController()
            }
            rootNavigationController.isNavigationBarHidden = false
            rootNavigationController.viewControllers = [receiptViewController]
        }
        
        return rootNavigationController
    }
    
    @objc public static func configureTabBarController(_ tabBarController: UITabBarController) {
        
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
