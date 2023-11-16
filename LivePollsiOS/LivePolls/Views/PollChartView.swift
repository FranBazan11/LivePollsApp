//
//  PollChartView.swift
//  LivePolls
//
//  Created by Juan Bazan Carrizo on 17/10/2023.
//

import SwiftUI
import Charts

struct PollChartView: View {
    // MARK: - PROPERTIES
   let options: [Option]
    
    // MARK: - BODY
    var body: some View {
        Chart(options) {
            BarMark(
                x: .value("Name", $0.name),
                y: .value("Count", $0.count)
            )
            .cornerRadius(5)
            .foregroundStyle(by: .value("Name", $0.name))
            
        }
        .padding()
    }
}

struct PollChartView_Previews: PreviewProvider {
    static var previews: some View {
        PollChartView(options: [
            .init(count: 3, name: "PS5"),
            .init(count: 5, name: "PS4"),
            .init(count: 2, name: "XBox"),
            .init(count: 1, name: "Switch")
        ])
    }
}
