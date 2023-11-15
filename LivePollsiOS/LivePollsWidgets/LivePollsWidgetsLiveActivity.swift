//
//  LivePollsWidgetsLiveActivity.swift
//  LivePollsWidgets
//
//  Created by Juan Bazan Carrizo on 19/10/2023.
//

import ActivityKit
import WidgetKit
import SwiftUI


// MARK: - LivePollsWidgetsAttributes
struct LivePollsWidgetsAttributes: ActivityAttributes {
    typealias ContentState = Poll
    
    
    public var pollId: String
    
    init(pollId: String) {
        self.pollId = pollId
    }
    
    
    /// Codigo base cuando se crea extension, no lo borro para entender bien como funciona
    /*
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var value: Int
    }
    */

    // Fixed non-changing properties about your activity go here!
    // var name: String
}

// MARK: - LivePollsWidgetsLiveActivity
struct LivePollsWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LivePollsWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                HStack {
                    Text(context.state.name)
                    Spacer()
                    Image(systemName: "chart.bar.xaxis")
                    
                    Text(String(context.state.totalCount))
                    
                    if let updatedAt = context.state.updatedAt {
                        Image(systemName: "clock.fill")
                        Text(updatedAt, style: .time)
                    }
                } //: HStack
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .padding(.bottom)
                
                PollChartView(options: context.state.options)
                    .frame(height: 100)
                
            } //: VStack
            .padding()
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.name).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(alignment: .top) {
                        Image(systemName: "chart.bar.xaxis")
                        Text(String(context.state.totalCount))
                    }
                    .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    PollChartView(options: context.state.options)
                        .frame(height: 100)
                }
            } compactLeading: {
                Text(context.state.lastUpdatedOption?.name ?? "-")
            } compactTrailing: {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                    Text(String(context.state.lastUpdatedOption?.count ?? 0))
                }
                .lineLimit(1)
            } minimal: {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                    Text(String(context.state.totalCount))
                }
                .lineLimit(1)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}


extension LivePollsWidgetsAttributes {
    fileprivate static var preview: LivePollsWidgetsAttributes {
        LivePollsWidgetsAttributes(pollId: "console")
    }
}

extension LivePollsWidgetsAttributes.ContentState {
    
    fileprivate static var first: LivePollsWidgetsAttributes.ContentState {
        LivePollsWidgetsAttributes.ContentState(updatedAt: Date(),
                                                name: "Favorite Console",
                                                totalCount: 100,
                                                options: [Option(count: 20, name: "XBOX S|X"),
                                                          Option(id: "ps5", count: 80, name: "PS5")],
                                                lastUpdatedOptionsId: "ps5")
         }
     
     fileprivate static var second: LivePollsWidgetsAttributes.ContentState {
         LivePollsWidgetsAttributes.ContentState(updatedAt: Date().addingTimeInterval(3600),
                                                 name: "Favorite Console",
                                                 totalCount: 160,
                                                 options: [Option(count: 20, name: "XBOX S|X"),
                                                           Option(id: "ps5", count: 140, name: "PS5")],
                                                 lastUpdatedOptionsId: "ps5")
     }
    
}



