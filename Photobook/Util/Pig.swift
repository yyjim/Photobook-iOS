//
//  Pig.swift
//  Photobook
//
//  Created by Jaime Landazuri on 27/06/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

enum PigError: Error {
    case parsing
}

// Utilities to deal with PIG images
class Pig {
    
    static var apiClient = APIClient.shared
    
    /// Uploads an image to PIG
    ///
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - completion: Completion block returning a URL or an error
    static func uploadImage(_ image: UIImage, completion: @escaping (_ url: String?, _ error: Error?) -> Void) {
        
        apiClient.uploadImage(image, imageName: "OrderSummaryPreviewImage.png", context: .pig, endpoint: "upload/") { (json, error) in

            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let dictionary = json as? [String: AnyObject], let url = dictionary["full"] as? String else {
                print("Pig: Couldn't parse URL of uploaded image")
                completion(nil, PigError.parsing)
                return
            }
            
            completion(url, nil)
        }
    }

    /// Fetches a composite image from PIG
    ///
    /// - Parameters:
    ///   - baseUrlString: The URL of the background image to use
    ///   - coverImageUrlString: The cover image or subject
    ///   - size: The required size for the resulting image
    ///   - completion: Completion block returning an image
    static func fetchPreviewImage(withBaseUrlString baseUrlString: String, coverImageUrlString: String, size: CGSize, completion: @escaping (UIImage?) -> Void) {

        let width = Int(size.width)
        let height = Int(size.height)
        
        let urlString = baseUrlString + "&image=" + coverImageUrlString + "&size=\(width)x\(height)" + "&fill_mode=match"
        guard let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) else {
            completion(nil)
            return
        }

        apiClient.downloadImage(url) { (image, _) in
            completion(image)
        }
    }
}