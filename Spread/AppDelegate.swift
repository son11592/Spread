//
//  AppDelegate.swift
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  var window: UIWindow?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions
    launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
      let rootViewController = ViewController()
      let window = UIWindow(frame: UIScreen.main.bounds)
      window.rootViewController = rootViewController
      
      self.window = window

      // Because of nil.
      window.makeKeyAndVisible()
      return true
  }
}

