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
    var monthYearTitle: String? {
        let dateComponents = Calendar.current.dateComponents([.month, .year], from: self)
        let monthSymbols = Calendar.current.monthSymbols
        guard let monthIndex = dateComponents.month, monthSymbols.count > monthIndex-1 else { return nil }
        var title: String = monthSymbols[monthIndex-1]
        if let year = dateComponents.year {
            title += " " + String(year)
        }
        return title
    }
    
    // MARK: - String -> Date
    static func getDate(from text: String, in format: String) -> Date? {
        NBDateTimeManager.shared.getDate(from: text, in: format)
    }
}
