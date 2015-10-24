//
//  SpreadTests.swift
//  SpreadTests
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

import Foundation
import Spread
import XCTest

class Model: SModel {
    
    dynamic var objectId: String!
    dynamic var name: String!
}

class SpreadTests: XCTestCase {
    private let pool1Identifier = "pool1Identifier"
    private let pool2Identifier = "pool2Identifier"
    private let pool3Identifier = "pool3Identifier"
    private let pool4Identifier = "pool4Identifier"
    
    private var model1Name = ""
    private var model2Name = ""
    private var model3Name = ""
    
    // Init data.
    private let model1Data = ["name": "One", "objectId": "match all object id"]
    private let model2Data = ["name": "Two", "objectId": "match all object id"]
    private let model3Data = ["name": "Three", "objectId": "match all object id"]
    private let model4Data = ["name": "Four", "objectId": "match all object id"]
    private let model5Data = ["name": "Five", "objectId": "match all object id"]
    
    private let poolChangeNameEvent = "ChangeName"
    
    override func setUp() {
        super.setUp()
        
        // Register class.
        Spread.registerClass(Model.classForCoder(), forPoolIdentifier: self.pool1Identifier)
        Spread.registerClass(Model.classForCoder(), forPoolIdentifier: self.pool2Identifier)
        Spread.registerClass(Model.classForCoder(), forPoolIdentifier: self.pool3Identifier)
        Spread.registerClass(Model.classForCoder(), forPoolIdentifier: self.pool4Identifier)
        
        // Register pool event.
        Spread.registerEvent(self.poolChangeNameEvent,
            poolIdentifiers:[self.pool1Identifier,
                self.pool2Identifier,
                self.pool3Identifier,
                self.pool4Identifier]) { (value, spool) -> Void in
                    
                    let objectId = (value as! NSDictionary).valueForKey("objectId") as! String
                    let newName = (value as! NSDictionary).valueForKey("name") as! String
                    let models = spool.allModels().filter({ (model) -> Bool in
                        return (model as! Model).objectId == objectId
                    })
                    for item in models {
                        let model = item as! Model
                        model.name = newName
                    }
        }
        
        // Add data to pool and binding data.
        let model1 = Spread.addObject(model1Data, toPool: self.pool1Identifier)
        model1.property("name", onEvent: SModelEvent.OnChange) { (oldValue, newValue) -> Void in
            self.model1Name = newValue as! String
        }
        Spread.addObject(model5Data, toPool: self.pool1Identifier)
        
        let model2 = Spread.addObject(model2Data, toPool: self.pool2Identifier)
        model2.property("name", onEvent: SModelEvent.OnChange) { (oldValue, newValue) -> Void in
            self.model2Name = newValue as! String
        }
        let model3 = Spread.addObject(model3Data, toPool: self.pool3Identifier)
        model3.property("name", onEvent: SModelEvent.OnChange) { (oldValue, newValue) -> Void in
            self.model3Name = newValue as! String
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCountingAddAndRemoveObejct() {
        let pool4 = Spread.getPool(self.pool4Identifier)
        let numberObjectBeforeAdd = pool4.allModels().count
        
        let model = Spread.addObject(model4Data, toPool: self.pool4Identifier)
        let numberObjectAfterAdded = pool4.allModels().count
        XCTAssertEqual(numberObjectBeforeAdd, numberObjectAfterAdded - 1)

        Spread.removeModel(model, fromPool: self.pool4Identifier)
        let numberObjectAfterRemove = pool4.allModels().count
        XCTAssertEqual(numberObjectAfterAdded, numberObjectAfterRemove + 1)
    }
    
    func testReactionWhenMatchObjectId() {
        
        Spread.outEvent(self.poolChangeNameEvent,
            value: ["name": "Change all name", "objectId": "match all object id"])
        
        Spread.outEvent(self.poolChangeNameEvent,
            value: ["name": "Change all name again", "objectId": "match all object id"])
        
        // All name of models should be changed.
        XCTAssertEqual(self.model1Name, "Change all name again")
        XCTAssertEqual(self.model2Name, "Change all name again")
        XCTAssertEqual(self.model3Name, "Change all name again")
    }
    
    func testReactionNotMatchObjectId() {
        Spread.outEvent(self.poolChangeNameEvent,
            value: ["name": "A new name", "objectId": "match all object id"])
        
        Spread.outEvent(self.poolChangeNameEvent,
            value: ["name": "Whatever", "objectId": "not match any object id"])
        
        // All name of models should not be changed.
        XCTAssertEqual(self.model1Name, "A new name")
        XCTAssertEqual(self.model2Name, "A new name")
        XCTAssertEqual(self.model3Name, "A new name")
    }
    
    func testRemoveReact() {
        Spread.outEvent(self.poolChangeNameEvent,
            value: ["name": "Name before remove", "objectId": "match all object id"])
        
        Spread.removeEvent(self.poolChangeNameEvent,
            poolIdentifiers: [self.pool1Identifier])
        
        Spread.outEvent(self.poolChangeNameEvent,
            value: ["name": "Name after remove", "objectId": "match all object id"])
        
        XCTAssertEqual(self.model1Name, "Name before remove")
    }
    
    func testPerformance() {
        self.measureBlock() {
            for _ in 1...1000 {
                Spread.addObject(self.model4Data, toPool: self.pool4Identifier)
            }
            for _ in 1...2 {
                Spread.outEvent(self.poolChangeNameEvent,
                    value: ["name": "A new name", "objectId": "match all object id"])
            }
        }
    }
    
    func testRemovePool() {
        Spread.removePoolWithIdentifier(self.pool2Identifier)
        let pool: SPool? = Spread.getPool(self.pool2Identifier)
        XCTAssertNil(pool, "Must be nil")
    }
}
