//
//  NBNCManager.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 29/12/23.
//

import Foundation

extension Notification.Name {
    static let NBCDManagerDidUpdateTransaction = Notification.Name(rawValue: "NBCDManager-didUpdateTransaction")
    static let NBCDManagerDidCreateNewTransactionPaymentMethod = Notification.Name(rawValue: "NBCDManager-didCreateNewTransactionPaymentMethod")
}

struct NBNCManager {
    private init() { }
    static let shared = NBNCManager()
    
    private let notificationCenter = NotificationCenter.default
    
//    func postNotification(name: Notification.Name) {
//        notificationCenter.post(Notification(name: name))
//    }
    func addObserver(_ observer: Any, selector: Selector, forNotification name: Notification.Name) {
        notificationCenter.addObserver(observer, selector: selector, name: name, object: nil)
    }
    func removeObserver(_ observer: Any, forNotification name: Notification.Name) {
        notificationCenter.removeObserver(observer, name: name, object: nil)
    }
}
