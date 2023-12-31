//
//  Date+Extension.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 30/12/23.
//

import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    // MARK: - String -> Date
    static func getDate(from text: String, in format: String) -> Date? {
        NBDateTimeManager.shared.getDate(from: text, in: format)
    }
}
