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
  fileprivate let pool1Indentifier = "Pool1Indentifier"
  fileprivate let pool2Indentifier = "Pool2Indentifier"
  fileprivate let pool3Indentifier = "Pool3Indentifier"
  
  fileprivate let action1Identifier = "ChangeCarrotName"
  
  // View components.
  fileprivate let textField = UITextField()
  
  fileprivate let carrot1Label = UILabel()
  fileprivate let carrot2Label = UILabel()
  fileprivate let carrot3Label = UILabel()
  fileprivate let milkCarrot = Carrot()
  
  override func loadView() {
    super.loadView()
    self.view.backgroundColor = UIColor.white
    
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
    
    SRemoteTaskManager.add(task1)
    SRemoteTaskManager.add(task2)
    SRemoteTaskManager.add(otherTask1)
    SRemoteTaskManager.add(otherTask2)
    SRemoteTaskManager.add(otherTask3)
    SRemoteTaskManager.add(otherTask4)
    SRemoteTaskManager.add(task3)
    SRemoteTaskManager.add(task4)
    SRemoteTaskManager.add(task5)
    SRemoteTaskManager.add(task6)
    
    // Config Spread pools.
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool1Indentifier, keep: true)
    Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool2Indentifier)
    let pool3 = Spread.registerClass(Carrot.classForCoder(), forPoolIdentifier: self.pool3Indentifier)
        
    pool3.onEvent(SPoolEvent.onChange, reaction: { (data) -> Void in
      NSLog("Pool reaction on init.")
    })
    pool3.onEvent(SPoolEvent.onChange, reaction: { (data) -> Void in
      NSLog("Pool reaction change.")
    })
    pool3.onEvent(SPoolEvent.onRemoveModel, reaction: { (data) -> Void in
      NSLog("Pool reaction on remove.")
    })
    
    // Register actions for pools.
    Spread.registerEvent(self.action1Identifier,
      poolIdentifiers: [self.pool1Indentifier, self.pool2Indentifier, self.pool3Indentifier])
      { (data, pool) -> Void in
        
        // Get new name and id.
        let newName = (data as! NSDictionary).value(forKey: "name") as! String
        let objctId = (data as! NSDictionary).value(forKey: "objectId") as! String
        
        // Select carrots in pool.
        let carrots = pool.allModels().filter({ (item) -> Bool in
          let carrot = item as! Carrot
          return (carrot.objectId == objctId as NSString)
        })
        
        // Change carrots name.
        for item in carrots {
          let carrot = item as! Carrot
          carrot.name = newName as NSString!
        }
    }
    
    // Create dummies data.
    let carrotData = ["name": "One", "objectId": "one"]
    let milk = Milk(dictionary: [AnyHashable: Any]())
    print("%@", milk.toDictionary())
    
    // Add object to pool and setup reaction.
    let carrotInPool1 = Spread.addObject(carrotData, toPool: self.pool1Indentifier) as! Carrot
    
    carrotInPool1.property("name", on: SModelEvent.onChange) { (oldValue, newValue) -> Void in
      self.carrot1Label.text = newValue as? String
    }
    
    let carrotInPool2 = Spread.addObject(carrotData, toPool: self.pool2Indentifier) as! Carrot
    carrotInPool2.property("name", on: SModelEvent.onChange) { (oldValue, newValue) -> Void in
      self.carrot2Label.text = newValue as? String
    }
    
    let carrotInPool3 = Spread.addObject(carrotData, toPool: self.pool3Indentifier) as! Carrot
    carrotInPool3.property("name", target: self, selector: #selector(ViewController.textChange), on: SModelEvent.onChange)
  }
  
  func textChange() {
    self.carrot3Label.text = self.textField.text
  }
  
  func initView() {
    self.textField.frame = CGRect(x: 10, y: 40, width: 300, height: 40)
    self.textField.addTarget(self, action: #selector(UITextViewDelegate.textViewDidChange(_:)),
      for: UIControlEvents.editingChanged)
    self.textField.backgroundColor = UIColor.green
    
    self.carrot1Label.frame = CGRect(x: 10, y: 100, width: 300, height: 40)
    self.carrot1Label.backgroundColor = UIColor.yellow
    
    self.carrot2Label.frame = CGRect(x: 10, y: 160, width: 300, height: 40)
    self.carrot2Label.backgroundColor = UIColor.yellow
    
    self.carrot3Label.frame = CGRect(x: 10, y: 220, width: 300, height: 40)
    self.carrot3Label.backgroundColor = UIColor.yellow
    
    self.view.addSubview(self.textField)
    self.view.addSubview(self.carrot1Label)
    self.view.addSubview(self.carrot2Label)
    self.view.addSubview(self.carrot3Label)
  }
  
  func textViewDidChange(_ textField: UITextField) {
    let text = textField.text
    Spread.outEvent(self.action1Identifier,
      value: ["name": text!, "objectId": "one"])
  }
}

