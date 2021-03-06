//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import XCTest
@testable import Photobook

class URLAssetTests: XCTestCase {
        
    func testURLAsset_canBeInitialised() {
        let urlAssetImage = URLAssetImage(url: testUrl, size: testSize)
        let date = Date()
        let urlAsset = URLAsset(identifier: "identifier", images: [urlAssetImage], albumIdentifier: "albumIdentifier", date: date)
        
        XCTAssertEqualOptional(urlAsset?.identifier, "identifier")
        XCTAssertEqualOptional(urlAsset?.images.first, urlAssetImage)
        XCTAssertEqualOptional(urlAsset?.albumIdentifier, "albumIdentifier")
        XCTAssertEqualOptional(urlAsset?.date, date)
    }
    
    func testURLAsset_failsWithEmptyImages() {
        let urlAsset = URLAsset(identifier: "identifier", images: [])
        XCTAssertNil(urlAsset)
    }
    
    func testURLAsset_sortsImagesByWidth() {
        let widths = [ 100.0, 200.0, 50.0, 20.0, 150.0 ]
        var urlAssetImages = [URLAssetImage]()
        for width in widths {
            let assetImage = URLAssetImage(url: testUrl, size: CGSize(width: width, height: 40.0))
            urlAssetImages.append(assetImage)
        }
        
        let urlAsset = URLAsset(identifier: "identifier", images: urlAssetImages)
        XCTAssertEqualOptional(urlAsset?.images.first?.size.width, 20.0)
        XCTAssertEqualOptional(urlAsset?.images[1].size.width, 50.0)
        XCTAssertEqualOptional(urlAsset?.images[2].size.width, 100.0)
        XCTAssertEqualOptional(urlAsset?.images[3].size.width, 150.0)
        XCTAssertEqualOptional(urlAsset?.images[4].size.width, 200.0)
    }
    
    func testURLAsset_canBeInitialisedWithOneImage() {
        let urlAsset = URLAsset(testUrl, size: testSize)
        
        XCTAssertEqualOptional(urlAsset.images.first?.url, testUrl, "Should initialise the image url")
        XCTAssertTrue(urlAsset.size ==~ testSize, "Should initialise the image size")
    }

    func testSize_returnLargestImageSize() {
        let widths = [ 100.0, 200.0, 50.0, 20.0, 150.0 ]
        var urlAssetImages = [URLAssetImage]()
        for width in widths {
            let assetImage = URLAssetImage(url: testUrl, size: CGSize(width: width, height: 40.0))
            urlAssetImages.append(assetImage)
        }
        
        let urlAsset = URLAsset(identifier: "identifier", images: urlAssetImages)
        XCTAssertEqualOptional(urlAsset?.size.width, 200.0, "Should match the width")
        XCTAssertEqualOptional(urlAsset?.size.height, 40.0, "Should match the height")
    }
    
    func testImage_usesTheURLThatIsLarger() {
        let tests = [
            // Width multiplier, height multiplier, expected URL suffix
            (150, 100, "/2"),
            (100, 150, "/2"),
            (200, 200, "/1"),
            (50, 400, "/3"),
            (1, 1, "/10")
        ]
        
        for (index, test) in tests.enumerated() {
            var urlAssetImages = [URLAssetImage]()
            for i in 1 ... 10 {
                let url = URL(string: testUrlString + "\(i)")!
                let assetImage = URLAssetImage(url: url, size: CGSize(width: i * test.0, height: i * test.1))
                urlAssetImages.append(assetImage)
            }
            
            let webImageManager = WebImageManagerMock()
            
            let expectation = XCTestExpectation(description: "returns image data of right size \(index)")
            
            guard let urlAsset = URLAsset(identifier: "identifier", images: urlAssetImages) else {
                XCTFail("Could not create URL asset")
                return
            }
            urlAsset.screenScale = 2.0
            urlAsset.webImageManager = webImageManager
            urlAsset.image(size: CGSize(width: 75.0, height: 75.0), loadThumbnailFirst: false, progressHandler: nil, completionHandler: { (image, error) in
                
                if let url = webImageManager.url, url.absoluteString.contains(test.2) {
                    expectation.fulfill()
                    return
                }
                XCTFail("Used incorrect URL for URL image request")
            })
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testImageData_shouldUseAConvertedImage() {
        let image = UIImage(color: .red)!
        let expectedImageData = image.jpegData(compressionQuality: 1.0)
        
        let urlAsset = URLAsset(testUrl, size: testSize)
        let webImageManager = WebImageManagerMock()
        webImageManager.imageStub = image
        
        urlAsset.webImageManager = webImageManager

        let expectation = XCTestExpectation(description: "uses image")

        urlAsset.imageData(progressHandler: nil) { (imageData, fileextension, _) in
            if expectedImageData == imageData {
                expectation.fulfill()
                return
            }
            XCTFail("Returned incorrect image data")
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldUseData() {
        let image = UIImage(color: .red)!
        let expectedImageData = image.jpegData(compressionQuality: 1.0)

        let urlAsset = URLAsset(testUrl, size: testSize)
        let webImageManager = WebImageManagerMock()
        webImageManager.imageDataStub = expectedImageData
        
        urlAsset.webImageManager = webImageManager
        
        let expectation = XCTestExpectation(description: "uses image")
        
        urlAsset.imageData(progressHandler: nil) { (imageData, fileextension, _) in
            if expectedImageData == imageData {
                expectation.fulfill()
                return
            }
            XCTFail("Returned incorrect image data")
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testImageData_shouldReturnErrorIfDataIsNotAnImage() {
        let data = Data(count: 32)
        
        let urlAsset = URLAsset(testUrl, size: testSize)
        let webImageManager = WebImageManagerMock()
        webImageManager.imageDataStub = data
        
        urlAsset.webImageManager = webImageManager
        
        let expectation = XCTestExpectation(description: "uses image")
        
        urlAsset.imageData(progressHandler: nil) { (imageData, fileextension, error) in
            if error != nil {
                expectation.fulfill()
                return
            }
            XCTFail("Should return an error")
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testURLAsset_canBeArchivedAndUnarchived() {
        
        var urlAssetImages = [URLAssetImage]()
        for _ in 1 ... 10 {
            let assetImage = URLAssetImage(url: testUrl, size: testSize)
            urlAssetImages.append(assetImage)
        }
        
        let date = Date()
        guard let urlAsset = URLAsset(identifier: "identifier", images: urlAssetImages, albumIdentifier: "albumIdentifier", date: date) else {
            XCTFail("Could not create URL asset")
            return
        }
        guard let data = try? PropertyListEncoder().encode(urlAsset) else {
            XCTFail("Should encode the URLAsset to data")
            return
        }
        guard archiveObject(data, to: "URLAssetTests.dat") else {
            XCTFail("Should save the URLAsset data to disk")
            return
        }
        guard let unarchivedData = unarchiveObject(from: "URLAssetTests.dat") as? Data else {
            XCTFail("Should unarchive the URLAsset as Data")
            return
        }
        guard let unarchivedUrlAsset = try? PropertyListDecoder().decode(URLAsset.self, from: unarchivedData) else {
            XCTFail("Should decode the URLAsset")
            return
        }

        XCTAssertEqualOptional(unarchivedUrlAsset.albumIdentifier, urlAsset.albumIdentifier)
        XCTAssertEqualOptional(unarchivedUrlAsset.identifier, urlAsset.identifier)
        XCTAssertEqualOptional(unarchivedUrlAsset.uploadUrl, urlAsset.uploadUrl)
        XCTAssertEqualOptional(unarchivedUrlAsset.date, urlAsset.date)
        XCTAssertEqualOptional(unarchivedUrlAsset.images.count, urlAsset.images.count)
    }    
}
