//
//  TextField.swift
//  TemplateKit
//
//  Created by Matias Cudich on 9/9/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation

public struct TextFieldProperties: ViewProperties {
  public var key: String?
  public var layout: LayoutProperties?
  public var style: StyleProperties?
  public var gestures: GestureProperties?

  public var textStyle = TextStyleProperties([:])
  public var onChange: Selector?
  public var onSubmit: Selector?
  public var placeholder: String?

  public init(_ properties: [String : Any]) {
    applyProperties(properties)
    textStyle = TextStyleProperties(properties)

    onChange = properties.get("onChange")
    onSubmit = properties.get("onSubmit")
    placeholder = properties.get("placeholder")
  }
}

public func ==(lhs: TextFieldProperties, rhs: TextFieldProperties) -> Bool {
  return lhs.textStyle == rhs.textStyle && lhs.onChange == rhs.onChange && lhs.onSubmit == rhs.onSubmit && lhs.placeholder == rhs.placeholder && lhs.equals(otherViewProperties: rhs)
}

public class TextField: UITextField, NativeView {
  public static var propertyTypes: [String: ValidationType] {
    return commonPropertyTypes.merged(with: [
      "text": Validation.string,
      "fontName": Validation.string,
      "fontSize": Validation.float,
      "textColor": Validation.color,
      "textAlignment": TextValidation.textAlignment,
      "onChange": Validation.selector,
      "onSubmit": Validation.selector,
      "placeholder": Validation.string
    ])
  }

  public var eventTarget: AnyObject?

  public var properties = TextFieldProperties([:]) {
    didSet {
      applyProperties()
    }
  }

  private var lastSelectedRange: UITextRange?

  public required init() {
    super.init(frame: CGRect.zero)

    addTarget(self, action: #selector(TextField.onChange), for: .editingChanged)
    addTarget(self, action: #selector(TextField.onSubmit), for: .editingDidEndOnExit)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func applyProperties() {
    applyCommonProperties()
    applyTextFieldProperties()
  }

  func applyTextFieldProperties() {
    guard let fontValue = UIFont(name: properties.textStyle.fontName, size: properties.textStyle.fontSize) else {
      fatalError("Attempting to use unknown font")
    }
    let attributes: [String : Any] = [
      NSFontAttributeName: fontValue,
      NSForegroundColorAttributeName: properties.textStyle.color
    ]
    borderStyle = .line
    selectedTextRange = lastSelectedRange
    tintColor = .black

    attributedText = NSAttributedString(string: properties.textStyle.text, attributes: attributes)
    textAlignment = properties.textStyle.textAlignment

    placeholder = properties.placeholder
  }

  func onChange() {
    lastSelectedRange = selectedTextRange
    if let onChange = properties.onChange {
      let _ = eventTarget?.perform(onChange, with: self)
    }
  }

  func onSubmit() {
    if let onSubmit = properties.onSubmit {
      let _ = eventTarget?.perform(onSubmit, with: self)
    }
  }
}
