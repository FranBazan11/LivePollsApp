//
//  PollViewModel.swift
//  LivePolls
//
//  Created by Juan Bazan Carrizo on 18/10/2023.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import ActivityKit

class PollViewModel: ObservableObject {
    // MARK: - PROPERTIES
    
    let db = Firestore.firestore()
    let pollId: String
    
    
    /// Checkear si esto tiene que ser published
    @Published var activity: Activity<LivePollsWidgetsAttributes>?
    @Published var poll: Poll?
    
    
    // MARK: - INITs
    init(pollId: String, poll: Poll? = nil) {
        self.pollId = pollId
        self.poll = poll
    }
    
    // MARK: - FUNCS
    @MainActor
    func listenToPoll() {
        db.document("polls/\(pollId)")
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error featching snapshot \(error.debugDescription)")
                    return
                }
                do {
                    let poll = try snapshot.data(as: Poll.self)
                    withAnimation {
                        self.poll = poll
                    }
                    self.startActivityIfNeeded()
                } catch {
                    print("Failed to fetch poll")
                }
            }
    }
    
    func incrementOption(_ option: Option) {
        guard let index = poll?.options.firstIndex(where: {$0.id == option.id}) else { return }
        db.document("polls/\(pollId)")
            .updateData([
                "totalCount": FieldValue.increment(Int64(1)),
                "option\(index).count": FieldValue.increment(Int64(1)),
                "lastUpdatedOptionId": option.id,
                "updatedAt": FieldValue.serverTimestamp()
            ])
    }
    
    func startActivityIfNeeded() {
        guard let poll, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        if let currentPollIdActivity = Activity<LivePollsWidgetsAttributes>.activities.first(where: { activity in activity.attributes.pollId == pollId }) {
            self.activity = currentPollIdActivity
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                Task {
                    await self.activity?.update(using: poll)
                }
            }
        } else {
            do {
                let activityAttributes = LivePollsWidgetsAttributes(pollId: pollId)
                let initialContentState = LivePollsWidgetsAttributes.ContentState(id: poll.id, createdAt: poll.createdAt, updatedAt: poll.updatedAt,
                                                                                  name: poll.name, totalCount: poll.totalCount, options: poll.options,
                                                                                  lastUpdatedOptionsId: poll.lastUpdatedOptionId)
                                    
                self.activity = try Activity<LivePollsWidgetsAttributes>.request(attributes: activityAttributes, contentState: initialContentState, pushType: nil)
            } catch {
                print("Error requesting Live Activities")
            }
        }
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        Task { [weak self] in
            guard let self = self else { return }
            guard let activity = self.activity else {
                print("activity is nil")
                return
            }
            
            for await token in activity.pushTokenUpdates {
                let tokenParts = token.map{ data in String(format: "%02.2hhx", data) }
                let token = tokenParts.joined()
                
                print("Live activitiy token updated \(token)")
                
                do {
                    try await self.db.collection("polls/\(pollId)/push_tokens")
                        .document(deviceId)
                        .setData([ "token": token ])
                } catch {
                    print("Failed to update token \(error.localizedDescription)")
                }
            }
        }
    }
}
