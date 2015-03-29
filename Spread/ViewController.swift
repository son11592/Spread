//
//  ViewController.swift
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  // Pool Identifiers.
  private let pool1Indentifier = "Pool1Indentifier"
  private let pool2Indentifier = "Pool2Indentifier"
  private let pool3Indentifier = "Pool3Indentifier"
  
  private let action1Identifier = "ChangeCarrotName"
  
  // View components.
  private let textField = UITextField()
  
  private let carrot1Label = UILabel()
  private let carrot2Label = UILabel()
  private let carrot3Label = UILabel()
  
  override func loadView() {
    
    super.loadView()
    self.view.backgroundColor = UIColor.whiteColor()
    
    // Setup view.
    self.initView()
    
    // Setup data.
    self.initData()
  }
  
  func initData() {
    
    NSLog("Magic is here...")
    
    // Config Spread pools.
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool1Indentifier)
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool2Indentifier)
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool3Indentifier)

    // Register actions for pools.
    Spread.registerEvent(self.action1Identifier,
      poolIdentifiers: [self.pool1Indentifier, self.pool2Indentifier, self.pool3Indentifier])
      { (data, pool) -> Void in
        
        // Get new name and id.
        let newName = (data as NSDictionary).valueForKey("name") as String
        let objctId = (data as NSDictionary).valueForKey("objectId") as String
       
        // Select carrots in pool.
        let carrots = pool.filter({ (item) -> Bool in
            let carrot = item as Carrot
            return (carrot.objectId == objctId)
        })
        
        // Change carrots name.
        for item in carrots {
            let carrot = item as Carrot
            carrot.name = newName
        }
    }
    
    // Create dummies data.
    let carrotData = ["name": "One", "objectId": "one"]
    
    // Add object to pool and setup reaction.
    let carrotInPool1 = Spread.addObject(carrotData, toPool: self.pool1Indentifier)
    carrotInPool1.property("name", reactOnChange: { (newValue) -> Void in
      
      self.carrot1Label.text = newValue as? String
    })

    let carrotInPool2 = Spread.addObject(carrotData, toPool: self.pool2Indentifier)
    carrotInPool2.property("name", reactOnChange: { (newValue) -> Void in
      
      self.carrot2Label.text = newValue as? String
    })
    
    let carrotInPool3 = Spread.addObject(carrotData, toPool: self.pool3Indentifier)
    carrotInPool3.property("name", reactOnChange: { (newValue) -> Void in
      
      self.carrot3Label.text = newValue as? String
    })
    
    // Remove carrot.
    Spread.removeObject(carrotInPool3, fromPool: self.pool3Indentifier)
    let pool3 = Spread.getPool(self.pool3Indentifier)
  }
  
  func initView() {
    
    self.textField.frame = CGRectMake(10, 40, 300, 40)
    self.textField.addTarget(self, action: "textViewDidChange:",
      forControlEvents: UIControlEvents.EditingChanged)
    self.textField.backgroundColor = UIColor.greenColor()
    
    self.carrot1Label.frame = CGRectMake(10, 100, 300, 40)
    self.carrot1Label.backgroundColor = UIColor.yellowColor()
    
    self.carrot2Label.frame = CGRectMake(10, 160, 300, 40)
    self.carrot2Label.backgroundColor = UIColor.yellowColor()
    
    self.carrot3Label.frame = CGRectMake(10, 220, 300, 40)
    self.carrot3Label.backgroundColor = UIColor.yellowColor()
    
    self.view.addSubview(self.textField)
    self.view.addSubview(self.carrot1Label)
    self.view.addSubview(self.carrot2Label)
    self.view.addSubview(self.carrot3Label)
  }
  
  func textViewDidChange(textField: UITextField) {
  
    let text = textField.text
    Spread.performEvent(self.action1Identifier,
      value: ["name": text, "objectId": "one"])
  }
}

