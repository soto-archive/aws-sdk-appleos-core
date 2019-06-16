//
//  XML.swift
//  AWSSDKSwift
//
//  Created by Adam Fowler on 2019/06/15
//
//
import Foundation

#if os(iOS)
/// base class for all types of XMLNode
public class XMLNode : CustomStringConvertible, CustomDebugStringConvertible {
    
    /// XML node type
    public enum Kind {
        case document
        case element
        case text
        case attribute
        case namespace
        case comment
    }
    
    /// defines the type of xml node
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

    /// create XML document node
    public static func document() -> XMLNode {
        return XMLDocument()
    }
    
    /// create XML element node
    public static func element(withName: String, stringValue: String? = nil) -> XMLNode {
        return XMLElement(name: withName, stringValue: stringValue)
    }
    
    /// create raw text node
    public static func text(stringValue: String) -> XMLNode {
        return XMLNode(.text, stringValue: stringValue)
    }
    
    /// create XML attribute node
    public static func attribute(withName: String, stringValue: String) -> XMLNode {
        return XMLNode(.attribute, name: withName, stringValue: stringValue)
    }
    
    /// create XML namespace node
    public static func namespace(withName: String, stringValue: String) -> XMLNode {
        return XMLNode(.namespace, name: withName, stringValue: stringValue)
    }
    
    /// create XML comment node
    public static func comment(stringValue: String) -> XMLNode {
        return XMLNode(.comment, stringValue: stringValue)
    }
    
    /// return child node at index
    private func child(at index: Int) -> XMLNode? {
        return children?[index]
    }
    
    /// return number of children
    public var childCount : Int { get {return children?.count ?? 0}}

    /// detach XML node from its parent
    public func detach() {
        parent?.children?.removeAll(where: {$0 === self})
        parent = nil
    }
    
    /// return children of a specific kind
    func children(of kind: Kind) -> [XMLNode]? {
        return children?.compactMap { $0.kind == kind ? $0 : nil }
    }
    
    private static let xmlEncodedCharacters : [String.Element: String] = [
        "\"": "&quot;",
        "&": "&amp;",
        "'": "&apos;",
        "<": "&lt;",
        ">": "&gt;",
    ]
    /// encode text with XML markup
    private static func xmlEncode(string: String) -> String {
        var newString = ""
        for c in string {
            if let replacement = XMLNode.xmlEncodedCharacters[c] {
                newString.append(contentsOf:replacement)
            } else {
                newString.append(c)
            }
        }
        return newString
    }
    
    /// output formatted XML
    public var xmlString : String {
        switch kind {
        case .text:
            if let stringValue = stringValue {
                return XMLNode.xmlEncode(string: stringValue)
            }
            return ""
        case .attribute, .namespace:
            if let name = name {
                return "\(name)=\"\(stringValue ?? "")\""
            } else {
                return ""
            }
        default:
            return ""
        }
    }
    
    /// CustomStringConvertible protocol
    public var description: String {return xmlString}
    /// CustomDebugStringConvertible protocol
    public var debugDescription: String {return xmlString}
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
        setRootElement(rootElement)
    }
    
    /// initialise with a block XML data
    public init(data: Data) throws {
        super.init(.document)
        do {
            let element = try XMLElement(xmlData: data)
            setRootElement(element)
        } catch XMLParsingError.emptyFile {
        }
    }

    /// set the root element of the document
    public func setRootElement(_ rootElement: XMLElement) {
        for child in self.children ?? [] {
            child.parent = nil
        }
        children = [rootElement]
    }
    
    /// return the root element
    public func rootElement() -> XMLElement? {
        return children?.first {return ($0 as? XMLElement) != nil} as? XMLElement
    }
    
    /// output formatted XML
    override public var xmlString: String {
        var string = "<?xml version=\"\(version ?? "1.0")\" encoding=\"\(characterEncoding ?? "UTF-8")\"?>"
        if let rootElement = rootElement() {
            string += rootElement.xmlString
        }
        return string
    }

    /// output formatted XML as Data
    public var xmlData : Data { return xmlString.data(using: .utf8) ?? Data()}

}

/// XML Element class
public class XMLElement : XMLNode {
    public init(name: String, stringValue: String? = nil) {
        super.init(.element, name: name)
        self.stringValue = stringValue
    }
    
    /// initialise XMLElement from xml data
    public init(xmlData: Data) throws {
        super.init(.element)
        let parser = XMLParser(data: xmlData)
        let parserDelegate = _XMLParserDelegate()
        parser.delegate = parserDelegate
        if !parser.parse() {
            if let error = parserDelegate.error {
                throw error
            }
        } else if let rootElement = parserDelegate.rootElement {
            self.setChildren(rootElement.children)
            self.name = rootElement.name
            self.stringValue = rootElement.stringValue
        } else {
            throw XMLParsingError.emptyFile
        }
    }
    
    /// initialise XMLElement from xml string
    convenience public init(xmlString: String) throws {
        let data = xmlString.data(using: .utf8)!
        try self.init(xmlData: data)
    }
    
    /// return children XML elements
    public func elements(forName: String) -> [XMLElement] {
        return children?.compactMap {
            if let element = $0 as? XMLElement, element.name == forName {
                return element
            }
            return nil
        } ?? []
    }

    /// return child text nodes all concatenated together
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
    
    /// add a child node to the xml element
    public func addChild(_ node: XMLNode) {
        if children == nil {
            children = [node]
        } else {
            children!.append(node)
        }
        node.parent = self
    }
    
    /// insert a child node at position in the list of children nodes
    public func insertChild(node: XMLNode, at index: Int) {
        children?.insert(node, at: index)
        node.parent = self
    }
    
    /// set this elements children nodes
    public func setChildren(_ children: [XMLNode]?) {
        for child in self.children ?? [] {
            child.parent = nil
        }
        self.children = children
        for child in self.children ?? [] {
            child.parent = self
        }
    }
    
    /// return attribute attached to element
    public func attribute(forName: String) -> XMLNode? {
        return children?.first {
            if $0.kind == .attribute && $0.name == forName {
                return true
            }
            return false
        }
    }
    
    /// add an attribute to an element. If one with this name already exists it is replaced
    public func addAttribute(_ node : XMLNode) {
        if let name = node.name, let attributeNode = attribute(forName: name) {
            attributeNode.detach()
        }
        addChild(node)
    }

    /// return namespace attached to element
    public func namespace(forName: String) -> XMLNode? {
        return children?.first {
            if $0.kind == .namespace && $0.name == forName {
                return true
            }
            return false
        }
    }
    
    /// add a namespace to an element. If one with this name already exists it is replaced
    public func addNamespace(_ node : XMLNode) {
        if let name = node.name, let attributeNode = namespace(forName: name) {
            attributeNode.detach()
        }
        addChild(node)
    }

    /// return formatted XML
    override public var xmlString : String {
        var string = ""
        string += "<\(name!)"
        string += children(of:.namespace)?.map({" "+$0.xmlString}).joined(separator:"") ?? ""
        string += children(of:.attribute)?.map({" "+$0.xmlString}).joined(separator:"") ?? ""
        string += ">"
        for node in children(of:.text) ?? [] {
            string += node.xmlString
        }
        for node in children(of:.element) ?? [] {
            string += node.xmlString
        }
        string += "</\(name!)>"
        return string
    }
}

/// XML parsing errors
enum XMLParsingError : Error {
    case emptyFile
}

/// extend XMLParserError to return a string version of the error
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
    
    var rootElement : XMLElement?
    var currentElement : XMLElement?
    var error : Error?
    
    override init() {
        self.currentElement = nil
        self.rootElement = nil
        super.init()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let element = XMLElement(name: elementName)
        for attribute in attributeDict {
            element.addAttribute(XMLNode.attribute(withName: attribute.key, stringValue: attribute.value))
        }
        if rootElement ==  nil {
            rootElement = element
        }
        currentElement?.addChild(element)
        currentElement = element
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = currentElement?.parent as? XMLElement
    }
    
    func parser(_ parser: XMLParser, foundCharacters: String) {
        if currentElement != nil {
            if currentElement!.stringValue == nil {
                currentElement!.stringValue = foundCharacters
            } else {
                currentElement!.stringValue! += foundCharacters
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

#endif // os(iOS)
