//
//  LivePollsWidgetsBundle.swift
//  LivePollsWidgets
//
//  Created by Juan Bazan Carrizo on 19/10/2023.
//

import WidgetKit
import SwiftUI

@main
struct LivePollsWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LivePollsWidgets()
        LivePollsWidgetsLiveActivity()
    }
}
