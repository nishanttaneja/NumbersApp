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
}
