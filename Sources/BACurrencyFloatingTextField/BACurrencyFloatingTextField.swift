//  The MIT License (MIT)
//
//  Copyright (c) 2020 bagusandinata
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

//
//  BACurrencyFloatingTextField.swift
//
//  Created by Bagus Andinata on 07/09/20.
//  Copyright © 2020 Bagus Andinata. All rights reserved.
//

import UIKit
import Foundation

@objc
public protocol BACurrencyFloatingTextFieldDelegate: class {
    @objc optional func floatingPlaceholder(_ textField: UITextField, isShown: Bool)
}

open class BACurrencyFloatingTextField: UITextField {
    //MARK: - VARS FLOATING PLACEHOLDER
    private var floatingLabel: UILabel!
    private var _placeholder: String?
    private var _placeholderSize: CGFloat = 0
    private var _floatingText: String = ""
    private var _floatingTextSize: CGFloat = 0
    private var _floatingActiveTextColor: UIColor?
    
    //MARK: - VARS CURRENCY
    private var maxDigits = 17
    private var defaultValue = 0.00
    private let currencyFormatter = NumberFormatter()
    private var previousValue = ""
    var value: Double {
        get {
            guard let _value = Double(getCleanNumberString()) else { return 0.0 }
            return _value/100
        }
        set { setAmount(newValue) }
    }
    
    //MARK: - DELEGATE
    public weak var BAdelegate: BACurrencyFloatingTextFieldDelegate?
    
    //MARK: - @IBInspectable Floating Placeholder
    @IBInspectable
    var floatingText: String {
        get { return !_floatingText.isEmpty ? _floatingText : (_placeholder ?? "")}
        set { _floatingText = newValue }
    }
    
    @IBInspectable
    var floatingTextSize: CGFloat {
        get { return _floatingTextSize != 0 ? _floatingTextSize : (self.font?.pointSize ?? 0.0)}
        set { _floatingTextSize = newValue }
    }
    
    @IBInspectable
    var floatingSpace: CGFloat = 10
    
    @IBInspectable
    var floatingTextColor: UIColor = .darkGray
    
    @IBInspectable
    var floatingActiveTextColor: UIColor? {
        get { return _floatingActiveTextColor != nil ? _floatingActiveTextColor : floatingTextColor }
        set { _floatingActiveTextColor = newValue }
    }
    
    //MARK: - @IBInspectable PLACEHOLDER
    @IBInspectable
    var placeholderColor: UIColor = .lightGray
    
    @IBInspectable
    var placeholderSize: CGFloat {
        get { return _placeholderSize != 0 ? _placeholderSize : (self.font?.pointSize ?? 0.0) }
        set { _placeholderSize = newValue }
    }
    
    //MARK: - @IBInspectable CURRENCY
    @IBInspectable
    var maxCurrencyDigit: Int {
        get { return maxDigits }
        set { maxDigits = newValue }
    }
    
    public init(frame: CGRect,
                floatingText: String = "",
                floatingTextSize: CGFloat = 0,
                floatingSpace: CGFloat = 10,
                floatingTextColor: UIColor = .darkGray,
                floatingActiveTextColor: UIColor? = nil,
                placeholderColor: UIColor = .lightGray,
                placeholderSize: CGFloat = 0) {
        super.init(frame: frame)
        
        self.floatingText = floatingText
        self.floatingTextSize = floatingTextSize
        self.floatingSpace = floatingSpace
        self.floatingTextColor = floatingTextColor
        self.placeholderColor = placeholderColor
        self.placeholderSize = placeholderSize
        
        initCurrency()
        initPlaceholder()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initCurrency()
        initPlaceholder()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        initAttributedPlaceholder()
    }
    
    //MARK: - UITextField Notifications
    open override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(textDidChange(_:)), name: UITextField.textDidChangeNotification, object: self)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    //MARK: - DID CHANGE TEXTFIELD
    @objc
    private func textDidChange(_ notification: Notification) {
        updateCurrency()
        updateFloatingPlaceholder()
    }
    
    public func setValueIfNeeded(value: Double) {
        self.value = value
        updateFloatingPlaceholder()
    }
    
    public func getValueIfNeeded() -> Double {
        return value
    }
    
    //MARK: - UPDATE CURRENCY
    private func updateCurrency() {
        let cursorOffset = getOriginalCursorPosition()
        let cleanNumericString = getCleanNumberString()
        let textFieldLength = text?.count
        let textFieldNumber = Double(cleanNumericString)
        
        if cleanNumericString.count <= maxDigits && textFieldNumber != nil {
            setAmount(textFieldNumber! / 100)
        } else {
            text = previousValue
        }
        
        setCursorOriginalPosition(cursorOffset, oldTextFieldLength: textFieldLength)
    }
    
    //MARK: - INIT CURRENCY
    private func initCurrency() {
        keyboardType = .numberPad
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale(identifier: "id_ID")
        currencyFormatter.minimumFractionDigits = 2
        currencyFormatter.maximumFractionDigits = 2
    }
    
    //MARK: - CURRENCY FUNCTION
    private func setAmount (_ amount : Double){
        let textFieldStringValue = currencyFormatter.string(from: NSNumber(value: amount))
        text = textFieldStringValue
        textFieldStringValue.flatMap { previousValue = $0 }
    }
    
    private func getCleanNumberString() -> String {
        return text?.components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted).joined() ?? "0"
    }
    
    private func getOriginalCursorPosition() -> Int{
        guard let selectedTextRange = selectedTextRange else { return 0 }
        return offset(from: beginningOfDocument, to: selectedTextRange.start)
    }
    
    private func setCursorOriginalPosition(_ cursorOffset: Int, oldTextFieldLength : Int?) {
        let newLength = text?.count
        let startPosition = beginningOfDocument
        if let oldTextFieldLength = oldTextFieldLength, let newLength = newLength, oldTextFieldLength > cursorOffset {
            let newOffset = newLength - oldTextFieldLength + cursorOffset
            let newCursorPosition = position(from: startPosition, offset: newOffset)
            if let newCursorPosition = newCursorPosition {
                let newSelectedRange = textRange(from: newCursorPosition, to: newCursorPosition)
                selectedTextRange = newSelectedRange
            }
        }
    }
    
    //MARK: - INIT PLACEHOLDER
    private func initPlaceholder() {
        _placeholder = placeholder
        placeholder = ""
        
        floatingLabel = UILabel(frame: CGRect.zero)
        floatingLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingLabel.clipsToBounds = true
        floatingLabel.textAlignment = .center
        self.addSubview(floatingLabel)
        self.bringSubviewToFront(self.subviews.last!)
        NSLayoutConstraint.activate([
            floatingLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        self.setNeedsDisplay()
    }
    
    //MARK: - INIT ATTRIBUTE PLACEHOLDER
    private func initAttributedPlaceholder() {
        floatingLabel.text = _placeholder
        floatingLabel.textColor = placeholderColor
        floatingLabel.font = floatingLabel.font.withSize(placeholderSize)
        
        guard let fontTextField = self.font else { return }
        floatingLabel.font = fontTextField
    }
    
    //MARK: - OPERATION FLOATING PLACEHOLDER
    private func updateFloatingPlaceholder() {
        if !self.hasText {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                self.hideFloatingPlaceholder()
                self.layoutIfNeeded()
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                self.showFloatingPlaceholder()
                self.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    private func showFloatingPlaceholder() {
        guard let fontTextField = self.font else { return }
        
        BAdelegate?.floatingPlaceholder?(self, isShown: true)
        
        let yPosition = (fontTextField.pointSize/2)+floatingSpace
        
        floatingLabel.text = floatingText
        floatingLabel.font = floatingLabel.font.withSize(floatingTextSize)
        floatingLabel.textColor = floatingActiveTextColor
        floatingLabel.transform = CGAffineTransform(translationX: floatingLabel.bounds.origin.x, y: -yPosition)
    }
    
    private func hideFloatingPlaceholder() {
        BAdelegate?.floatingPlaceholder?(self, isShown: false)
        
        initAttributedPlaceholder()
        floatingLabel.transform = CGAffineTransform(translationX: floatingLabel.bounds.origin.x, y: floatingLabel.bounds.origin.y)
    }
}
