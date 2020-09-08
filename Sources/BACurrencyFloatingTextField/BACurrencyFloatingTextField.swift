import UIKit
import Foundation

open class BACurrencyFloatingTextField: UITextField {
    //MARK: - VARS FLOATING PLACEHOLDER
    private var floatingLabel: UILabel!
    private var _placeholder: String?
    
    //MARK: - VARS CURRENCY
    private let maxDigits = 17
    private var defaultValue = 0.00
    private let currencyFormatter = NumberFormatter()
    private var previousValue = ""
    var value: Double {
        get { return Double(getCleanNumberString())! / 100 }
        set { setAmount(newValue) }
    }
    
    //MARK: - @IBInspectable Floating Placeholder
    @IBInspectable
    var floatingText: String = "" {
        didSet {
            floatingLabel.text = floatingText.isEmpty ? placeholder : floatingText
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var floatingTextSize: CGFloat = 0 {
        didSet {
            floatingTextSize = floatingTextSize != 0 ? floatingTextSize : self.font!.pointSize
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var floatingSpace: CGFloat = 10
    
    @IBInspectable
    var floatingTextColor: UIColor = .darkGray
    
    @IBInspectable
    var floatingActiveTextColor: UIColor? {
        didSet {
            floatingActiveTextColor = floatingActiveTextColor != nil ? floatingActiveTextColor : floatingTextColor
        }
    }
    
    //MARK: - PLACEHOLDER
    @IBInspectable
    var placeholderColor: UIColor = .lightGray
    
    @IBInspectable
    var placeholderSize: CGFloat = 0 {
        didSet {
            placeholderSize = placeholderSize != 0 ? placeholderSize : self.font!.pointSize
            setNeedsDisplay()
        }
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
        
        print(value)
        print(Double(getCleanNumberString())! / 100)
        
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
        
        let yPosition = (fontTextField.pointSize/2)+floatingSpace
        
        floatingLabel.text = floatingText
        floatingLabel.font = floatingLabel.font.withSize(floatingTextSize)
        floatingLabel.textColor = floatingActiveTextColor
        floatingLabel.transform = CGAffineTransform(translationX: floatingLabel.bounds.origin.x, y: -yPosition)
    }
    
    private func hideFloatingPlaceholder() {
        initAttributedPlaceholder()
        floatingLabel.transform = CGAffineTransform(translationX: floatingLabel.bounds.origin.x, y: floatingLabel.bounds.origin.y)
    }
}
