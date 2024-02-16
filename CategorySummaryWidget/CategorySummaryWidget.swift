//
//  CategorySummaryWidget.swift
//  CategorySummaryWidget
//
//  Created by Nishant Taneja on 14/02/24.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let date = Date()
        let dateTimeSummary: NBDateTimeManager.NBDateTimeSummary = .monthly
        let startDateTime: Date
        switch dateTimeSummary {
        case .today:
            startDateTime = date.startOfDay
        case .weekly:
            startDateTime = date.startOfWeek ?? date
        case .monthly:
            startDateTime = date.startOfMonth ?? date
        }
        var entry = SimpleEntry(date: date, configuration: configuration, dateTimeSummary: dateTimeSummary)
        do {
            let transactions = try await NBCDManager.shared.loadAllTransactions(afterDateTime: startDateTime)
            entry.amountDescription = "₹" + String(format: "%.2f", transactions.reduce(Double.zero, { partialResult, transaction in
                var sum = partialResult
                if transaction.debitAccount != nil {
                    sum += transaction.amount
                }
                if transaction.creditAccount != nil {
                    sum -= transaction.amount
                }
                return sum
            }))
        } catch let error {
            debugPrint(#function, error.localizedDescription)
        }
        return Timeline(entries: [entry], policy: .never)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    var dateTimeSummary: NBDateTimeManager.NBDateTimeSummary?
    var amountDescription: String?
}

struct CategorySummaryWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text(entry.dateTimeSummary?.title ?? "")
                .font(.caption)
            Text(entry.amountDescription ?? "")
                .bold()
        }
    }
}

struct CategorySummaryWidget: Widget {
    let kind: String = "CategorySummaryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            CategorySummaryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    CategorySummaryWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .smiley)
    SimpleEntry(date: .now, configuration: .starEyes)
}
