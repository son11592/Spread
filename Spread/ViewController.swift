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
  private let milkCarrot = Carrot()
  
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
    
    let task1 = Task(objectId: "1", nameSpace: "Carrot 1")
    
    // This one will be cancel.
    let task2 = Task(objectId: "1", nameSpace: "Carrot 2")
    
    let task3 = Task(objectId: "1", nameSpace: "Carrot 2")
  
    let task4 = Task(objectId: "1", nameSpace: "Carrot 4")
    let task5 = Task(objectId: "1", nameSpace: "Carrot 5")
    let task6 = Task(objectId: "1", nameSpace: "Carrot 6")
    
    task1.addHanlder { (response, error) -> Void in
      NSLog("Task 1 complete")
    }
    task2.addHanlder { (response, error) -> Void in
      NSLog("Task 2 complete")
    }
    task3.addHanlder { (response, error) -> Void in
      NSLog("Task 3 complete")
    }
    task4.addHanlder { (response, error) -> Void in
      NSLog("Task 4 complete")
    }
    task5.addHanlder { (response, error) -> Void in
      NSLog("Task 5 complete")
    }
    task6.addHanlder { (response, error) -> Void in
      NSLog("Task 6 complete")
    }
    
    let otherTask1 = OtherTask(objectId: "1", nameSpace: "Carrot 2")
    
    // This one will be remove.
    let otherTask2 = OtherTask(objectId: "1", nameSpace: "Carrot 1")
    let otherTask3 = OtherTask(objectId: "1", nameSpace: "Carrot 1")
    
    let otherTask4 = OtherTask(objectId: "1", nameSpace: "Carrot 1")

    otherTask1.addHanlder { (response, error) -> Void in
      NSLog("Other task 1 complete")
    }
    otherTask2.addHanlder { (response, error) -> Void in
      NSLog("Other task 2 complete")
    }
    otherTask3.addHanlder { (response, error) -> Void in
      NSLog("Other task 3 complete")
    }
    otherTask4.addHanlder { (response, error) -> Void in
      NSLog("Other task 4 complete")
    }
    
    SRemoteTaskManager.addTask(task1)
    SRemoteTaskManager.addTask(task2)
    SRemoteTaskManager.addTask(otherTask1)
    SRemoteTaskManager.addTask(otherTask2)
    SRemoteTaskManager.addTask(otherTask3)
    SRemoteTaskManager.addTask(otherTask4)
    SRemoteTaskManager.addTask(task3)
    SRemoteTaskManager.addTask(task4)
    SRemoteTaskManager.addTask(task5)
    SRemoteTaskManager.addTask(task6)
    
    // Config Spread pools.
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool1Indentifier)
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool2Indentifier)
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool3Indentifier)
    
    let pool3 = Spread.getPool(self.pool3Indentifier)
    pool3.onEvent(SPoolEvent.OnInitModel, reaction: { (data) -> Void in
      
      NSLog("Pool reaction on init.")
    })
    
    pool3.onEvent(SPoolEvent.OnChange, reaction: { (data) -> Void in
      
      NSLog("Pool reaction change.")
    })
    
    pool3.onEvent(SPoolEvent.OnRemoveModel, reaction: { (data) -> Void in
      
      NSLog("Pool reaction on remove.")
    })
    
    // Register actions for pools.
    Spread.registerEvent(self.action1Identifier,
      poolIdentifiers: [self.pool1Indentifier, self.pool2Indentifier, self.pool3Indentifier])
      { (data, pool) -> Void in
        
        // Get new name and id.
        let newName = (data as! NSDictionary).valueForKey("name") as! String
        let objctId = (data as! NSDictionary).valueForKey("objectId") as! String
        
        // Select carrots in pool.
        let carrots = pool.allObjects().filter({ (item) -> Bool in
          let carrot = item as! Carrot
          return (carrot.objectId == objctId)
        })
        
        // Change carrots name.
        for item in carrots {
          let carrot = item as! Carrot
          carrot.name = newName
        }
    }
    
    // Create dummies data.
    let carrotData = ["name": "One", "objectId": "one"]
    
    // Add object to pool and setup reaction.
    let carrotInPool1 = Spread.addObject(carrotData, toPool: self.pool1Indentifier)
    carrotInPool1.property("name", onEvent: SModelEvent.OnChange) { (oldValue, newValue) -> Void in
      self.carrot1Label.text = newValue as? String
    }
    
    let carrotInPool2 = Spread.addObject(carrotData, toPool: self.pool2Indentifier)
    carrotInPool2.property("name", onEvent: SModelEvent.OnChange) { (oldValue, newValue) -> Void in
      self.carrot2Label.text = newValue as? String
    }
    
    let carrotInPool3 = Spread.addObject(carrotData, toPool: self.pool3Indentifier)
    
    NSLog("\(carrotInPool3.toDictionary())")
    
    carrotInPool3.property("name", target: self, selector: "textChange", onEvent: SModelEvent.OnChange)
  }
  
  func textChange() {
    self.carrot3Label.text = self.textField.text
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
    Spread.outEvent(self.action1Identifier,
      value: ["name": text, "objectId": "one"])
  }
}

