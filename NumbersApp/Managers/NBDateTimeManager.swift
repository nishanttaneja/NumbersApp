//
//  NBDateTimeManager.swift
//  NumbersApp
//
//  Created by Nishant Taneja on 31/12/23.
//

import Foundation

struct NBDateTimeManager {
    private init() { }
    static let shared = NBDateTimeManager()
    
    private let dateFormatter = DateFormatter()
    
    func getDate(from text: String, in format: String) -> Date? {
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: text)
    }
    func getDateString(from date: Date, in format: String) -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
}

extension NBDateTimeManager {
    enum NBDateTimeSummary: CaseIterable {
        case today, weekly, monthly
        
        var title: String {
            let today = Date.now
            switch self {
            case .today:
                return "Today, " + today.formatted(date: .abbreviated, time: .omitted)
            case .weekly:
                guard let startOfWeek = today.startOfWeek, let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek) else { return "This Week" }
                let dateFormat = "dd MMM"
                return startOfWeek.getDateString(in: dateFormat) + " - " + endOfWeek.getDateString(in: dateFormat)
            case .monthly:
                return today.monthYearTitle ?? "This Month"
            }
        }
        var startDate: Date? {
            let today = Date.now
            switch self {
            case .today:
                return today.startOfDay
            case .weekly:
                return today.startOfWeek
            case .monthly:
                return today.startOfMonth
            }
        }
    }
}


// MARK: - Date+Ext
extension Date {
    static func getDate(from text: String, in format: String) -> Date? {
        NBDateTimeManager.shared.getDate(from: text, in: format)
    }
    func getDateString(in format: String) -> String {
        NBDateTimeManager.shared.getDateString(from: self, in: format)
    }
}
