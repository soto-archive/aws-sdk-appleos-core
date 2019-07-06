//
//  XMLTests.swift
//  AWSSDKSwiftCoreTests
//
//  Created by Adam Fowler 2019/07/06
//

import Foundation
import XCTest
@testable import AWSSDKSwiftCore

#if os(iOS) || os(tvOS)

class XMLTests: XCTestCase {

    /// helper test function to use throughout all the decode/encode tests
    func testDecodeEncode(xml: String) {
        do {
            let xmlDocument = try AWSSDKSwiftCore.XMLDocument(data: xml.data(using: .utf8)!)
            let xml2 = xmlDocument.xmlString
            XCTAssertEqual(xml, xml2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testAddChild() {
        let element = XMLElement(name:"test")
        let element2 = XMLElement(name:"test2")
        element.addChild(element2)
        element2.addChild(XMLNode.text(stringValue: "TestString") as! XMLNode)
        XCTAssertEqual(element.xmlString, "<test><test2>TestString</test2></test>")
    }
    func testAddRemoveChild() {
        let element = XMLElement(name:"test")
        let element2 = XMLElement(name:"test2")
        element.addChild(element2)
        element2.addChild(XMLNode.text(stringValue: "TestString") as! XMLNode)
        element2.detach()
        XCTAssertEqual(element.xmlString, "<test></test>")
    }
    func testAttributeAdd() {
        let element = XMLElement(name:"test", stringValue: "data")
        element.addAttribute(XMLNode.attribute(withName: "attribute", stringValue: "value") as! XMLNode)
        XCTAssertEqual(element.xmlString, "<test attribute=\"value\">data</test>")
    }
    func testAttributeReplace() {
        let element = XMLElement(name:"test", stringValue: "data")
        element.addAttribute(XMLNode.attribute(withName: "attribute", stringValue: "value") as! XMLNode)
        element.addAttribute(XMLNode.attribute(withName: "attribute", stringValue: "value2") as! XMLNode)
        XCTAssertEqual(element.xmlString, "<test attribute=\"value2\">data</test>")
    }
    func testNamespaceAdd() {
        let element = XMLElement(name:"test", stringValue: "data")
        element.addNamespace(XMLNode.namespace(withName: "name", stringValue: "http://me.com/") as! XMLNode)
        XCTAssertEqual(element.xmlString, "<test xmlns:name=\"http://me.com/\">data</test>")
    }
    func testNamespaceReplace() {
        let element = XMLElement(name:"test", stringValue: "data")
        element.addNamespace(XMLNode.namespace(withName: "name", stringValue: "http://me2.com/") as! XMLNode)
        XCTAssertEqual(element.xmlString, "<test xmlns:name=\"http://me2.com/\">data</test>")
    }
    func testAttributesDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test name=\"test\">testing</test>"
        testDecodeEncode(xml: xml)
    }
    func testNamespacesDecodeEncode() {
        let xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><test xmlns:h=\"http://www.w3.org/TR/html4/\">testing</test>"
        testDecodeEncode(xml: xml)
    }
}

#endif
