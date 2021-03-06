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

import UIKit

protocol TextEditingDelegate: class {
    func didChangeFontType()
    func didChangeText()
    func shouldReactToKeyboardAppearance() -> Bool
}

class TextEditingViewController: UIViewController {

    private struct Constants {
        static let keyboardInitialBottomConstraint: CGFloat = 100.0
    }
    
    @IBOutlet private weak var textToolBarView: TextToolBarView! {
        didSet { textToolBarView.delegate = self }
    }
    @IBOutlet private weak var textViewBorderView: UIView!
    @IBOutlet private weak var textView: PhotobookTextView!
    @IBOutlet private weak var pageView: UIView!
    @IBOutlet private weak var assetContainerView: UIView!
    @IBOutlet private weak var assetPlaceholderIconImageView: UIImageView!
    @IBOutlet private weak var assetImageView: UIImageView!
    
    @IBOutlet private weak var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textViewBottomConstraint: NSLayoutConstraint!
    
    var productLayout: ProductLayout! {
        didSet { hasAnImageLayout = (productLayout.layout.imageLayoutBox != nil) }
    }
    var pageType: PageType!
    var assetImage: UIImage?
    var pageColor: ProductColor!
    var initialContainerRect: CGRect?
    weak var delegate: TextEditingDelegate?

    private lazy var animatableAssetImageView = UIImageView()
    private var hasAnImageLayout: Bool!
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.alpha = 0.0
        
        textView.textContainer.lineFragmentPadding = 0.0
        textView.textContainerInset = .zero
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    private var hasPlacedPageView = false
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard !hasPlacedPageView, delegate?.shouldReactToKeyboardAppearance() ?? false else { return }
        hasPlacedPageView = true
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Code placed here animate along with the keyboard, hence the closure
            UIView.performWithoutAnimation {
                textViewBottomConstraint.constant = keyboardSize.height
                self.pageView.center = CGPoint(x: self.pageView.center.x, y: self.pageView.center.y - (keyboardSize.height - Constants.keyboardInitialBottomConstraint))
                self.performAnimations()
            }
        }
    }
    
    private var animateOnFinishedCompletion: (() -> Void)!
    func animateOn(_ completion: @escaping (() -> Void)) {
        animateOnFinishedCompletion = completion
        
        // Place views according to layout
        setup()
        
        textView.becomeFirstResponder()
    }
    
    private var isAnimatingOnScreen = false
    private func performAnimations() {
        guard let initialContainerRect = initialContainerRect else { return }
        
        isAnimatingOnScreen = true
        
        textViewBorderView.alpha = 0.0
        textView.alpha = 0.0
        
        let backgroundColor = view.backgroundColor
        view.backgroundColor = .clear
        view.alpha = 1.0
        pageView.layoutIfNeeded()
        
        // Take a view snapshot and shrink it to the initial frame
        var targetRect = CGRect.zero
        if hasAnImageLayout {
            animatableAssetImageView.transform = .identity
            animatableAssetImageView.frame = assetContainerView.frame
            animatableAssetImageView.image = assetContainerView.snapshot()
            animatableAssetImageView.center = CGPoint(x: initialContainerRect.midX, y: initialContainerRect.midY)

            targetRect = pageView.convert(assetContainerView.frame, to: view)
            let initialScale = initialContainerRect.width / targetRect.width
            animatableAssetImageView.transform = CGAffineTransform.identity.scaledBy(x: initialScale, y: initialScale)
            
            view.addSubview(animatableAssetImageView)
        } else {
            animatableAssetImageView.image = nil
            animatableAssetImageView.alpha = 0.0
        }
        
        assetContainerView.alpha = 0.0
        
        // Re-enable animations
        UIView.setAnimationsEnabled(true)

        UIView.animate(withDuration: 0.1) {
            self.view.backgroundColor = backgroundColor
        }

        if !hasAnImageLayout {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut], animations: {
                self.textViewBorderView.alpha = 1.0
                self.textView.alpha = 1.0
            }, completion: { _ in
                self.isAnimatingOnScreen = false
                self.animateOnFinishedCompletion()
            })
            return
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.1, options: [.curveEaseInOut], animations: {
            self.animatableAssetImageView.frame = targetRect
        }, completion: { _ in
            self.animatableAssetImageView.alpha = 0.0
            self.assetContainerView.alpha = 1.0
        })
        
        UIView.animate(withDuration: 0.15, delay: 0.28, options: [.curveEaseInOut], animations: {
            self.textViewBorderView.alpha = 1.0
            self.textView.alpha = 1.0
        }, completion: { _ in
            self.isAnimatingOnScreen = false
            self.animateOnFinishedCompletion()
        })

    }
    
    func visibleTextInLayout() -> String? {
        return textView.visibleText
    }
    
    func animateOff(completion: @escaping () -> Void) {
        guard !isAnimatingOnScreen, let initialContainerRect = initialContainerRect else { return }

        if hasAnImageLayout {
            animatableAssetImageView.alpha = 1.0
            assetContainerView.alpha = 0.0
        }

        let backgroundColor = view.backgroundColor

        if !hasAnImageLayout {
            UIView.animate(withDuration: 0.1, animations: {
                self.textView.alpha = 0.0
                self.textViewBorderView.alpha = 0.0
            })

            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
                self.view.backgroundColor = .clear
            }, completion: { _ in
                self.animatableAssetImageView.alpha = 1.0
                self.view.alpha = 0.0
                self.view.backgroundColor = backgroundColor
                
                self.hasPlacedPageView = false
                completion()
            })
            return
        }

        UIView.animate(withDuration: 0.1, delay: 0.2, animations: {
            self.view.backgroundColor = .clear
        })
        
        textView.alpha = 0.0
        textViewBorderView.alpha = 0.0
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.animatableAssetImageView.frame = initialContainerRect
        }, completion: { _ in
            self.view.alpha = 0.0
            self.view.backgroundColor = backgroundColor
            
            self.hasPlacedPageView = false
            completion()
        })
    }
    
    private func setup() {
        // Figure out the height of the textView
        guard let textLayoutBox = productLayout?.layout.textLayoutBox
        else {
            fatalError("Text editing failed due to missing layout info.")
        }
        
        let pageRatio = pageType == .cover ? product.photobookTemplate.coverAspectRatio : product.photobookTemplate.pageAspectRatio
        
        textView.inputAccessoryView = textToolBarView
        textView.text = productLayout.text
        
        let aspectRatio = textLayoutBox.aspectRatio(forContainerRatio: pageRatio)
        textViewHeightConstraint.constant = textView.bounds.width / aspectRatio
        
        // Place it above the selectors to begin with
        textViewBottomConstraint.constant = Constants.keyboardInitialBottomConstraint
        
        // Position page and image box, if needed
        let layoutBoxSize = CGSize(width: textView.bounds.width, height: textViewHeightConstraint.constant)
        let pageSize = textLayoutBox.containerSize(for: layoutBoxSize)
        
        let topMargin = view.bounds.height - textViewBottomConstraint.constant - textViewHeightConstraint.constant
        let textLayoutBoxRect = textLayoutBox.rectContained(in: pageSize)
        let pageXCoordinate = textViewLeadingConstraint.constant - textLayoutBoxRect.minX
        let pageYCoordinate = topMargin - textLayoutBoxRect.minY
        
        pageView.frame.origin = CGPoint(x: pageXCoordinate, y: pageYCoordinate)
        pageView.frame.size = pageSize
        view.backgroundColor = pageColor.uiColor()
        
        // Set up the textField font
        let fontType: FontType
        if let productLayoutText = productLayout.productLayoutText {
            fontType = productLayoutText.fontType
        } else {
            fontType = .plain
        }
        setTextViewAttributes(with: fontType, fontColor: pageColor.fontColor())
        
        textToolBarView.select(fontType: fontType)
        
        // Place image if needed
        guard let imageLayoutBox = productLayout!.layout.imageLayoutBox else {
            assetContainerView.alpha = 0.0
            return
        }
        assetContainerView.alpha = 1.0
        
        let imageLayoutRect = imageLayoutBox.rectContained(in: pageSize)
        assetContainerView.frame = imageLayoutRect

        guard let asset = productLayout?.asset,
              let image = assetImage else {
                setImagePlaceholder(visible: true)
                return
        }
        setImagePlaceholder(visible: false)
        
        assetImageView.image = image
        assetImageView.transform = .identity
        assetImageView.frame = CGRect(x: 0.0, y: 0.0, width: asset.size.width, height: asset.size.height)
        assetImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
        
        productLayout!.productLayoutAsset!.containerSize = assetContainerView.bounds.size
        assetImageView.transform = productLayout!.productLayoutAsset!.transform
    }
    
    private func setImagePlaceholder(visible: Bool) {
        if visible {
            assetImageView.image = nil
            assetContainerView.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
            let iconSize = min(assetContainerView.bounds.width, assetContainerView.bounds.height)
            assetPlaceholderIconImageView.bounds.size = CGSize(width: iconSize * 0.1, height: iconSize * 0.1)
            assetPlaceholderIconImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
            assetPlaceholderIconImageView.alpha = 1.0
        } else {
            assetContainerView.backgroundColor = .clear
            assetPlaceholderIconImageView.alpha = 0.0
        }
    }

    private func setTextViewAttributes(with fontType: FontType, fontColor: UIColor) {
        let pageHeight = pageType == .cover ? product.photobookTemplate.coverSize.height : product.photobookTemplate.pageSize.height
        let fontSize = fontType.sizeForScreenToPageRatio(pageView.bounds.height / pageHeight)
        textView.attributedText = fontType.attributedText(with: textView.text, fontSize: fontSize, fontColor: fontColor)
        textView.typingAttributes = fontType.typingAttributes(fontSize: fontSize, fontColor: fontColor)
    }
    
    private func textGoesOverBounds(for textView: UITextView, string: String, range: NSRange) -> Bool {
        let viewHeight = textView.bounds.height
        let width = textView.textContainer.size.width
        
        let attributedString = NSMutableAttributedString(attributedString: textView.textStorage)
        attributedString.replaceCharacters(in: range, with: string)
        
        let textHeight = (attributedString as NSAttributedString).height(for: width)
        return textHeight >= viewHeight
    }
}

extension TextEditingViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let textView = textView as! PhotobookTextView
        
        // Dismiss on line break
        guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
            guard !isAnimatingOnScreen else { return false }
            
            productLayout.setText(textView.text, withLineBreaks: textView.lineBreakIndexes())

            textView.resignFirstResponder()
            delegate?.didChangeText()
            return false
        }
        
        return textView.shouldChangePhotobookText(in: range, replacementText: text)
    }
}

extension TextEditingViewController: TextToolBarViewDelegate {
    
    func didSelectFontType(_ fontType: FontType) {
        setTextViewAttributes(with: fontType, fontColor: pageColor.fontColor())
        
        productLayout.fontType = fontType
        delegate?.didChangeFontType()
    }
}
