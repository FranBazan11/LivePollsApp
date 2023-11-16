//
//  PollView.swift
//  LivePolls
//
//  Created by Juan Bazan Carrizo on 18/10/2023.
//

import SwiftUI

struct PollView: View {
    @StateObject var pollViewModel: PollViewModel
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Text("Poll ID")
                    Text(pollViewModel.pollId)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                
                HStack {
                    Text("Updated at")
                    Spacer()
                    if let updatedAt = pollViewModel.poll?.updatedAt {
                        Text(updatedAt, style: .time)
                    }
                }
                
                HStack {
                    Text("Total vote count")
                    Spacer()
                    if let totalCount = pollViewModel.poll?.totalCount {
                        Text(String(totalCount))
                    }
                }
            } //: Section
            
            if let pollOptions = pollViewModel.poll?.options {
                PollChartView(options: pollOptions)
                
                Section("Vote") {
                    ForEach(pollOptions) { option in
                        Button {
                            pollViewModel.incrementOption(option)
                        } label: {
                            HStack {
                                Text("+1")
                                Text(option.name)
                                Spacer()
                                Text(String(option.count))
                            }
                        }
                    }
                }
            }
        } //: List
        .navigationTitle(pollViewModel.poll?.name ?? "")
        .onAppear {
            pollViewModel.listenToPoll()
        }
    }
}

struct PollView_Previews: PreviewProvider {
    static var previews: some View {
        PollView(pollViewModel: PollViewModel(pollId: "1C689A50-6E17-42B0-A0E8-1688146E8F5E"))
    }
}
