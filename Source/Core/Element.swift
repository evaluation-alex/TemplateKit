//
//  Element.swift
//  TemplateKit
//
//  Created by Matias Cudich on 9/3/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation

public protocol ElementRepresentable {
  var tagName: String { get }
  func make(_ element: Element, _ owner: Node?) -> Node
  func equals(_ other: ElementRepresentable) -> Bool
}

public protocol Element: Keyable, StyleElement {
  var type: ElementRepresentable { get }
  var children: [Element]? { get }
  var parent: Element? { get set }

  func build(with owner: Node?, context: Context?) -> Node
  mutating func applyStyleSheet(_ styleSheet: StyleSheet?)
}

public extension StyleElement where Self: Element {
  var parentElement: StyleElement? {
    return parent
  }

  var childElements: [StyleElement]? {
    return children
  }

  public func equals(_ other: Element?) -> Bool {
    return key == other?.key && (other?.parent?.equals(other?.parent) ?? (other?.parent == nil))
  }

  func matches(attribute: String, with value: String) -> Bool {
    return false
  }

  public func directAdjacent(of element: StyleElement) -> StyleElement? {
    guard let children = children, let index = index(of: element), index > 0 else {
      return nil
    }

    return children[index - 1]
  }

  public func indirectAdjacents(of element: StyleElement) -> [StyleElement] {
    guard let children = children, let index = index(of: element), index > 0 else {
      return []
    }

    return Array(children[0..<index])
  }

  public func subsequentAdjacents(of element: StyleElement) -> [StyleElement] {
    guard let children = children, let index = index(of: element), index < children.count - 1 else {
      return []
    }

    return Array(children[index + 1..<children.count])
  }

  private func index(of child: StyleElement) -> Int? {
    guard let children = children else {
      return nil
    }

    return children.index { child in
      return child.equals(child)
    }
  }
}

public struct ElementData<PropertiesType: Properties>: Element {
  public let type: ElementRepresentable
  public private(set) var children: [Element]?
  public var parent: Element?
  public var properties: PropertiesType

  public var id: String? {
    return properties.core.identifier.id
  }

  public var classNames: [String]? {
    return properties.core.identifier.classNames
  }

  public var tagName: String? {
    return type.tagName
  }

  public var key: String? {
    get {
      return properties.core.identifier.key
    }
    set {
      properties.core.identifier.key = newValue
    }
  }

  public init(_ type: ElementRepresentable, _ properties: PropertiesType, _ children: [Element]? = nil) {
    self.type = type
    self.properties = properties
    self.children = children

    for (index, child) in (self.children ?? []).enumerated() {
      self.children?[index].parent = self
      self.children?[index].key = child.key ?? "\(index)"
    }
  }

  public func build(with owner: Node?, context: Context? = nil) -> Node {
    let made = type.make(self, owner)

    made.context = context

    return made
  }

  public func has(attribute: String, with value: String) -> Bool {
    return properties.has(key: attribute, withValue: value)
  }

  public mutating func applyStyleSheet(_ styleSheet: StyleSheet?) {
    let matchingStyles = styleSheet?.stylesForElement(self)
    var styleSheetProperties = [String: Any]()
    for (name, declaration) in (matchingStyles ?? [:]) {
      styleSheetProperties[name] = declaration.values[0]
    }

    var styledProperties = PropertiesType(styleSheetProperties)
    styledProperties.merge(self.properties)
    self.properties = styledProperties

    for (index, _) in (children ?? []).enumerated() {
      children?[index].applyStyleSheet(styleSheet)
    }
  }
}
