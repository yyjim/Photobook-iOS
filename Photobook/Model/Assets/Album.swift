//
//  Album.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol Album {
    
    /// Returns the estimated number of assets of this album, which might be available without calling loadAssets. It might differ from the actual number of assets. Returns NSNotFound if it isn't available.
    var numberOfAssets: Int { get }
    var localizedName: String? { get }
    var identifier: String { get }
    var assets: [Asset] { get }
    
    func loadAssets(completionHandler: ((_ error: Error?) -> Void)?)
    func coverImage(size: CGSize, completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> Void)
    
}