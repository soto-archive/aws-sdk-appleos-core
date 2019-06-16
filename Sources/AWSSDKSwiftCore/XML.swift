//
//  XML.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/06/15
//
//
import Foundation

public class XMLNode {
    public enum Kind {
        case document
        case element
        case text
        case attribute
        case namespace
        case comment
    }
    
    public let kind : Kind
    public var name : String?
    public var stringValue : String?
    public fileprivate(set) var children : [XMLNode]?
    public weak var parent : XMLNode?
    
    public init(_ kind: Kind, name: String? = nil, stringValue: String? = nil) {
        self.kind = kind
        self.name = name
        self.stringValue = stringValue
        self.children = nil
        self.parent = nil
    }

    public static func document() -> XMLNode {
        return XMLDocument()
    }
    
    public static func element(withName: String, stringValue: String? = nil) -> XMLNode {
        return XMLElement(name: withName, stringValue: stringValue)
    }
    
    public static func text(stringValue: String) -> XMLNode {
        return XMLNode(.text, stringValue: stringValue)
    }
    
    public static func attribute(withName: String, stringValue: String) -> XMLNode {
        return XMLNode(.attribute, name: withName, stringValue: stringValue)
    }
    
    public static func namespace(withName: String, stringValue: String) -> XMLNode {
        return XMLNode(.namespace, name: withName, stringValue: stringValue)
    }
    
    public static func comment(stringValue: String) -> XMLNode {
        return XMLNode(.comment, stringValue: stringValue)
    }
    
    private func child(at index: Int) -> XMLNode? {
        return children?[index]
    }
    
    public var childCount : Int { get {return children?.count ?? 0}}

    public func addChild(_ node: XMLNode) {
        if children == nil {
            children = [node]
        } else {
            children!.append(node)
        }
        node.parent = self
    }
    
    public func insertChild(node: XMLNode, at index: Int) {
        children?.insert(node, at: index)
        node.parent = self
    }
    
    public func detach() {
        parent?.children?.removeAll(where: {$0 === self})
        parent = nil
    }
    
    public func setChildren(_ children: [XMLNode]?) {
        for child in self.children ?? [] {
            child.parent = nil
        }
        self.children = children
        for child in self.children ?? [] {
            child.parent = self
        }
    }
    
    func children(of kind: Kind) -> [XMLNode]? {
        return children?.compactMap { $0.kind == kind ? $0 : nil }
    }
    
    public var xmlString : String {
        switch kind {
        case .text:
            return stringValue ?? ""
        case .attribute, .namespace:
            if let name = name {
                return "\(name)='\(stringValue ?? "")"
            } else {
                return ""
            }
        default:
            return ""
        }
    }
}

/// XML Document class
public class XMLDocument : XMLNode {
    public var version : String?
    public var characterEncoding : String?
    
    public init() {
        super.init(.document)
    }

    public init(rootElement: XMLElement) {
        super.init(.document)
        addChild(rootElement)
    }
    
    public init(data: Data) throws {
        super.init(.document)
        do {
            let element = try XMLElement(xmlData: data)
            addChild(element)
        } catch XMLParsingError.emptyFile {
        }
    }

    func rootElement() -> XMLElement? {
        return children?.first {return ($0 as? XMLElement) != nil} as? XMLElement
    }
    
    var xmlData : Data { return xmlString.data(using: .utf8) ?? Data()}

}

/// XML Element class
public class XMLElement : XMLNode {
    public init(name: String, stringValue: String? = nil) {
        super.init(.element, name: name)
        self.stringValue = stringValue
    }
    
    public init(xmlData: Data) throws {
        super.init(.element)
        let parser = XMLParser(data: xmlData)
        let parserDelegate = _XMLParserDelegate()
        parser.delegate = parserDelegate
        if !parser.parse() {
            if let error = parserDelegate.error {
                throw error
            }
        } else if let rootNode = parserDelegate.rootNode {
            self.setChildren(rootNode.children)
            self.name = rootNode.name
            self.stringValue = rootNode.stringValue
        } else {
            throw XMLParsingError.emptyFile
        }
    }
    
    convenience public init(xmlString: String) throws {
        let data = xmlString.data(using: .utf8)!
        try self.init(xmlData: data)
    }
    
    public func elements(forName: String) -> [XMLElement] {
        return children?.compactMap {
            if let element = $0 as? XMLElement, element.name == forName {
                return element
            }
            return nil
        } ?? []
    }

    public override var stringValue : String? {
        get {
            let textNodes = children(of:.text)
            let text = textNodes?.reduce("", { return $0 + ($1.stringValue ?? "")})
            return text
        }
        set(value) {
            children?.removeAll {$0.kind == .text}
            if let value = value {
                addChild(XMLNode.text(stringValue: value))
            }
        }
    }
    
    public func attribute(forName: String) -> XMLNode? {
        return children?.first {
            if $0.kind == .attribute && $0.name == forName {
                return true
            }
            return false
        }
    }
    
    public func addAttribute(_ node : XMLNode) {
        if let name = node.name, let attributeNode = attribute(forName: name) {
            attributeNode.detach()
        }
        addChild(node)
    }

    public func namespace(forName: String) -> XMLNode? {
        return children?.first {
            if $0.kind == .namespace && $0.name == forName {
                return true
            }
            return false
        }
    }
    
    public func addNamespace(_ node : XMLNode) {
        if let name = node.name, let attributeNode = namespace(forName: name) {
            attributeNode.detach()
        }
        addChild(node)
    }

    override public var xmlString : String {
        var string = ""
        string += "<\(name!)"
        string += children(of:.namespace)?.map({" "+$0.xmlString}).joined(separator:"") ?? ""
        string += children(of:.attribute)?.map({" "+$0.xmlString}).joined(separator:"") ?? ""
        string += ">"
        for node in children(of:.element) ?? [] {
            string += node.xmlString
        }
        string += stringValue ?? ""
        string += "</\(name!)>"
        return string
    }
}

enum XMLParsingError : Error {
    case emptyFile
}

extension XMLParsingError {
    var localizedDescription: String {
        switch self {
        case .emptyFile:
            return "File contained nothing"
        }
    }
}

/// parser delegate used in XML parsing
fileprivate class _XMLParserDelegate : NSObject, XMLParserDelegate {
    
    var rootNode : XMLNode?
    var currentNode : XMLNode?
    var error : Error?
    
    override init() {
        self.currentNode = nil
        self.rootNode = nil
        super.init()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let element = XMLElement(name: elementName)
        for attribute in attributeDict {
            element.addAttribute(XMLNode.attribute(withName: attribute.key, stringValue: attribute.value))
        }
        if rootNode ==  nil {
            rootNode = element
        }
        currentNode?.addChild(element)
        currentNode = element
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentNode = currentNode?.parent
    }
    
    func parser(_ parser: XMLParser, foundCharacters: String) {
        if currentNode != nil {
            if currentNode!.stringValue == nil {
                currentNode!.stringValue = foundCharacters
            } else {
                currentNode!.stringValue! += foundCharacters
            }
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        error = parseError
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        error = validationError
    }
}

