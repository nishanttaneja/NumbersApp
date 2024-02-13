//
//  PendingDuesWidget.swift
//  PendingDuesWidget
//
//  Created by Nishant Taneja on 14/02/24.
//

import WidgetKit
import SwiftUI

struct CardProvider: AppIntentTimelineProvider {
    typealias Intent = PendingDuesAppIntent
    typealias Entry = CardEntry
    
    func placeholder(in context: Context) -> CardEntry {
        CardEntry(date: .now, card: nil)
    }
    func snapshot(for configuration: PendingDuesAppIntent, in context: Context) async -> CardEntry {
        CardEntry(date: .now, card: nil)
    }
    func timeline(for configuration: PendingDuesAppIntent, in context: Context) async -> Timeline<CardEntry> {
        var entries = [CardEntry]()
        entries.append(CardEntry(date: .now, card: configuration.card))
        return Timeline(entries: entries, policy: .never)
    }
}

struct CardEntry: TimelineEntry {
    let date: Date
    let card: CardEntity?
}

struct PendingDuesWidgetEntryView : View {
    var entry: CardEntry

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text(entry.card?.title ?? "No Card")
                        .font(.caption)
                        .italic()
                    Text("₹" + String(format: "%.2f", entry.card?.amount ?? .zero))
                        .font(.title3)
                }
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Text("\(entry.date.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }
}

struct PendingDuesWidget: Widget {
    let kind: String = "PendingDuesWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PendingDuesAppIntent.self, provider: CardProvider()) { entry in
            PendingDuesWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    PendingDuesWidget()
} timeline: {
    CardEntry(date: .now, card: nil)
    CardEntry(date: .now, card: nil)
}
