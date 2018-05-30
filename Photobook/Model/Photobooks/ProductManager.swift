//
//  ProductManager.swift
//  Photobook
//
//  Created by Jaime Landazuri on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class ProductManager {
    
    static let shared = ProductManager()
    
    private lazy var apiManager = PhotobookAPIManager()
    
    #if DEBUG
    convenience init(apiManager: PhotobookAPIManager) {
        self.init()
        self.apiManager = apiManager
    }
    #endif
    
    // Public info about photobook products
    private(set) var products: [PhotobookTemplate]?
    
    // List of all available layouts
    private(set) var layouts: [Layout]?
    
    // List of all available upsell options
    private(set) var upsellOptions: [UpsellOption]?
    
    var minimumRequiredPages: Int {
        return currentProduct?.template.minPages ?? 20
    }
    var maximumAllowedPages: Int {
        return currentProduct?.template.maxPages ?? 70
    }
    
    var apiKey: String? {
        didSet { apiManager.apiKey = apiKey }
    }
    
    private(set) var currentProduct: PhotobookProduct?
    
    func reset() {
        currentProduct = nil
    }
    
    /// Requests the photobook details so the user can start building their photobook
    ///
    /// - Parameter completion: Completion block with an optional error
    func initialise(completion: ((Error?) -> ())?) {
        apiManager.requestPhotobookInfo { [weak welf = self] (photobooks, layouts, upsellOptions, error) in
            guard error == nil else {
                completion?(error!)
                return
            }
            
            welf?.products = photobooks
            welf?.layouts = layouts
            welf?.upsellOptions = upsellOptions
            
            completion?(nil)
        }
    }
    
    private func coverLayouts(for photobook: PhotobookTemplate) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.coverLayouts.contains($0.id) }
    }
    
    private func layouts(for photobook: PhotobookTemplate) -> [Layout]? {
        guard let layouts = layouts else { return nil }
        return layouts.filter { photobook.layouts.contains($0.id) }
    }
    
    func setCurrentProduct(with photobook: PhotobookTemplate, assets: [Asset]? = nil) -> PhotobookProduct? {
        guard let availableCoverLayouts = coverLayouts(for: photobook),
              let availableLayouts = layouts(for: photobook)
        else { return nil }
        
        // Replacing template
        if currentProduct != nil {
            currentProduct?.setTemplate(photobook, coverLayouts: availableCoverLayouts, layouts: availableLayouts)
        } else if let assets = assets { // First time or replacing product
            currentProduct = PhotobookProduct(template: photobook, assets: assets, coverLayouts: availableCoverLayouts, layouts: availableLayouts)
        }
        return currentProduct
    }
}
