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
    var startOfWeek: Date? {
        let currentCalendar = Calendar.current
        return currentCalendar.date(from: currentCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
    }
    var startOfMonth: Date? {
        let currentCalendar = Calendar.current
        return currentCalendar.date(from: currentCalendar.dateComponents([.month, .year], from: self))
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
    var weekDayTitle: String? {
        let dateComponents = Calendar.current.dateComponents([.weekday, .weekOfYear, .yearForWeekOfYear], from: self)
        let weekSymbols = Calendar.current.weekdaySymbols
        guard let weekIndex = dateComponents.weekday, weekSymbols.count > weekIndex-1 else { return nil }
        return weekSymbols[weekIndex-1]
    }
}
