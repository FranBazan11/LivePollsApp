//
//  HomeView.swift
//  LivePolls
//
//  Created by Juan Bazan Carrizo on 17/10/2023.
//

import SwiftUI

struct HomeView: View {
    @StateObject var homeViewModel = HomeViewModel()
    
    var body: some View {
        List {
            existingPollSection
            livePollSection
            createPollSection
            addOptionsSection
            deleteOptionPoll
            
        } //: List
        .alert("Erorr", isPresented: .constant(homeViewModel.error != nil)) {
             
        } message: {
            Text(homeViewModel.error ?? "an error ocurred")
        }
        .sheet(item: $homeViewModel.modalPollId, content: { id in
            NavigationStack {
                PollView(pollViewModel: PollViewModel(pollId: id))
            }
        })
        .navigationTitle("LivePolls")
        .onAppear {
            homeViewModel.listenToLivePolls()
        }
    }
    
    // MARK: - LivePollSection
    var livePollSection: some View {
        Section {
            DisclosureGroup("Latest Live Polls") {
                ForEach(homeViewModel.polls) { poll in
                    VStack {
                        HStack(alignment: .top) {
                            Text(poll.name)
                            Spacer()
                            Image(systemName: "chart.bar.xaxis")
                            Text(String(poll.totalCount))
                            if let updatedAt = poll.updatedAt {
                                Image(systemName: "clock.fill")
                                Text(updatedAt, style: .date)
                            }
                        } //: HStack
                        
                        PollChartView(options: poll.options)
                    } //:VStack
                    .padding(.vertical)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        homeViewModel.modalPollId = poll.id
                    }
                } //: ForEach
            } //: DisclosureGroup
        } //: Section
    }
    
    // MARK: - CreatePollSection
    var createPollSection: some View {
        Section {
            TextField("Enter poll name", text: $homeViewModel.newPollName, axis: .vertical)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            Button("Submit") {
                Task { await homeViewModel.createNewPoll() }
            }
            .disabled(homeViewModel.isCreateNewPollButtonDisabled)
            
            if homeViewModel.isLoading {
                ProgressView()
            }
        } header: {
            Text("Create a Poll")
        } footer: {
            Text("Enter a poll name and 2-4 options to submit")
        }
    }
    
    // MARK: - AddOptionsSection
    
    var addOptionsSection: some View {
        Section("Options") {
            TextField("Enter option name", text: $homeViewModel.newOptionName, axis: .vertical)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("+ Add Option") {
                homeViewModel.addOption()
            }
            .disabled(homeViewModel.isAddNewPollButtonDisabled)
            
            ForEach(homeViewModel.newPollOptions, id: \.self) { option in
                Text(option)
            }.onDelete { indexSet in
                homeViewModel.newPollOptions.remove(atOffsets: indexSet)
            }
        }
    }
    
    // MARK: - DeleteOptionPoll
    var deleteOptionPoll: some View {
        Section("Delete Poll") {
            TextField("Enter poll name", text: $homeViewModel.deletePollName, axis: .vertical)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            Button("Delete") {
                Task { await homeViewModel.deletePoll() }
            }
            .disabled(homeViewModel.isDeleteButtonDisabled)
        }
    }
    
    // MARK: - ExistingPollSection
    var existingPollSection: some View {
        Section() {
            DisclosureGroup("Join a poll") {
                TextField("Enter a poll id", text: $homeViewModel.existingPollId)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Join") {
                    Task { await homeViewModel.joinExistingPoll() }
                }
                .disabled(homeViewModel.isJoinPollButtonDisabled)
            }
        }
    }
}

// MARK: - PREVIEW
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
