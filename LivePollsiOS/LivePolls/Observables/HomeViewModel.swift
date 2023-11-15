//
//  HomeViewModel.swift
//  LivePolls
//
//  Created by Juan Bazan Carrizo on 17/10/2023.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class HomeViewModel: ObservableObject {
    let db = Firestore.firestore()
    
    @Published var polls = [Poll]()
    
    @Published var error: String? = nil
    
    @Published var newPollName: String = ""
    @Published var newOptionName: String = ""
    @Published var deletePollName: String = ""
    @Published var newPollOptions: [String] = []
    @Published var modalPollId: String? = nil
    
    
    @Published var existingPollId: String = ""
    
    @Published var isLoading = false
    
    var isCreateNewPollButtonDisabled: Bool {
        isLoading || newPollName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newPollOptions.count < 2
    }
    
    var isAddNewPollButtonDisabled: Bool {
        isLoading || newOptionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newPollOptions.count == 4
    }
    
    var isDeleteButtonDisabled: Bool {
        isLoading || deletePollName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isJoinPollButtonDisabled: Bool {
        isLoading || existingPollId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - FUNCTIONS
    @MainActor
    func listenToLivePolls() {
        db.collection("polls")
            .order(by: "updatedAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error featching snapshot \(error.debugDescription)")
                    return
                }
                let docs = snapshot.documents
                let polls = docs.compactMap { data in
                    try? data.data(as: Poll.self)
                }
                
                withAnimation {
                    self.polls = polls
                }
            }
    }
    
    @MainActor
    func createNewPoll() async {
        isLoading = true
        defer { isLoading = false }
        
        let poll = Poll(name: newPollName.trimmingCharacters(in: .whitespacesAndNewlines),
                        totalCount: 0,
                        options: newPollOptions.map{ Option(count: 0, name: $0) })
        do {
            try db.document("polls/\(poll.id)")
                .setData(from: poll)
            self.newPollName = ""
            self.newOptionName = ""
            self.newPollOptions = []
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func addOption() {
        self.newPollOptions.append(newOptionName.trimmingCharacters(in: .whitespacesAndNewlines))
        self.newOptionName = ""
    }
    
    
    @MainActor
    func deletePoll() async {
        isLoading = true
        defer { isLoading = false }
        
        
        if let pollID = self.polls.first(where: { poll in poll.name == deletePollName })?.id {
            do {
                try await db.collection("polls").document(pollID).delete()
                self.deletePollName = ""
            } catch {
                print("Error")
            }
        }
    }
    
    @MainActor
    func joinExistingPoll() async {
        isLoading = true
        defer { isLoading = false }
        
        guard let existingPoll = try? await db.document("polls/\(existingPollId)").getDocument(), existingPoll.exists else {
            error = "Poll ID \(existingPollId) doesn't exists"
            return }
        withAnimation {
            modalPollId = existingPollId
        }
    }
    
}
