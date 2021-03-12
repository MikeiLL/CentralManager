//
//  LocalNotification.swift
//  CentralManager
//
//  Created by Alain Hsu on 2021/3/12.
//  Copyright © 2021 Uy Nguyen Long. All rights reserved.
//

import UIKit

class LocalNotification {
    static let shared = LocalNotification()

    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { (granted, error) in })
    }


    func notify(title: String, text: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = text
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "MyNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
