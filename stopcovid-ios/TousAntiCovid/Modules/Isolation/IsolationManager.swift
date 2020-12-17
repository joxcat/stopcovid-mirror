// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  IsolationManager.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 08/12/2020 - for the TousAntiCovid project.
//

import UIKit
import RobertSDK
import StorageSDK
import ServerSDK

protocol IsolationChangesObserver: class {
    
    func isolationDidUpdate()
    
}

final class IsolationObserverWrapper: NSObject {
    
    weak var observer: IsolationChangesObserver?
    
    init(observer: IsolationChangesObserver) {
        self.observer = observer
    }
    
}

final class IsolationManager {
    
    static let shared: IsolationManager = IsolationManager()
    
    // MARK: - Public workable values -
    var currentState: State? { State(rawValue: isolationState ?? "") }
    var currentRecommendationState: RecommendationState {
        return calculateRecommendationState()
    }
    
    private var storageManager: StorageManager!
    private var canTriggerUpdateNotif: Bool = true
        
    // MARK: - Primary values -
    private var isolationState: String? {
        get { storageManager.isolationState() }
        set {
            storageManager.saveIsolationState(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationLastContactDate: Date? {
        get { storageManager.isolationLastContactDate() }
        set {
            storageManager.saveIsolationLastContactDate(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationIsKnownIndexAtHome: Bool? {
        get { storageManager.isolationIsKnownIndexAtHome() }
        set {
            storageManager.saveIsolationIsKnownIndexAtHome(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationKnowsIndexSymptomsEndDate: Bool? {
        get { storageManager.isolationKnowsIndexSymptomsEndDate() }
        set {
            storageManager.saveIsolationKnowsIndexSymptomsEndDate(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationIndexSymptomsEndDate: Date? {
        get { storageManager.isolationIndexSymptomsEndDate() }
        set {
            storageManager.saveIsolationIndexSymptomsEndDate(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationIsTestNegative: Bool? {
        get { storageManager.isolationIsTestNegative() }
        set {
            storageManager.saveIsolationIsTestNegative(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationPositiveTestingDate: Date? {
        get { storageManager.isolationPositiveTestingDate() }
        set {
            storageManager.saveIsolationPositiveTestingDate(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationIsHavingSymptoms: Bool? {
        get { storageManager.isolationIsHavingSymptoms() }
        set {
            storageManager.saveIsolationIsHavingSymptoms(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationSymptomsStartDate: Date? {
        get { storageManager.isolationSymptomsStartDate() }
        set {
            storageManager.saveIsolationSymptomsStartDate(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationIsStillHavingFever: Bool? {
        get { storageManager.isolationIsStillHavingFever() }
        set {
            storageManager.saveIsolationIsStillHavingFever(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private(set) var isolationIsFeverReminderScheduled: Bool? {
        get { storageManager.isolationIsFeverReminderScheduled() }
        set {
            storageManager.saveIsolationIsFeverReminderScheduled(newValue)
            canTriggerUpdateNotif ? notifyObservers() : ()
        }
    }
    
    private var observers: [IsolationObserverWrapper] = []
    
    // MARK: - Calculated values -
    var currentIsolationEndDate: Date? {
        let date: Date?
        switch currentState {
        case .contactCase:
            date = contactCaseIsolationEndDate
        case .positiveCase:
            date = positiveCaseIsolationEndDate
        default:
            date = nil
        }
        return date?.roundingToBeginningOfDay()
    }
    
    var stillHavingFeverNotificationTriggerDate: Date {
        return currentIsolationEndDate ?? Date()
    }
    
    // MARK: - Contact case dates calculated values -
    private var contactCaseIsolationContactCalculatedDate: Date {
        let date: Date
        if RBManager.shared.isSick {
            date = isolationLastContactDate ?? Date()
        } else {
            date = isolationLastContactDate ?? storageManager.currentRiskScoringDate() ?? storageManager.currentWarningRiskScoringDate() ?? Date()
        }
        return date
    }
    
    private var contactCaseIsolationStartDate: Date? {
        let date: Date? = isolationIndexSymptomsEndDate ?? contactCaseIsolationContactCalculatedDate
        return date?.roundingToBeginningOfDay()
    }
    private var contactCaseIsolationEndDate: Date? {
        guard let startDate = contactCaseIsolationStartDate else { return nil }
        let date: Date = startDate.addingTimeInterval(ParametersManager.shared.isolationDuration)
        return date.roundingToBeginningOfDay()
    }
    private var isContactCaseIsolationEnded: Bool? {
        guard let date = contactCaseIsolationEndDate else { return nil }
        return Date() >= date
    }
    private var contactCasePostIsolationEndDate: Date? {
        guard let startDate = contactCaseIsolationStartDate else { return nil }
        let date: Date = startDate.addingTimeInterval(ParametersManager.shared.isolationDuration + ParametersManager.shared.postIsolationDuration)
        return date.roundingToBeginningOfDay()
    }
    private var isContactCasePostIsolationEnded: Bool? {
        guard let date = contactCasePostIsolationEndDate else { return nil }
        return Date() >= date
    }
    
    // MARK: - Positive case dates calculated values -
    private var positiveCaseIsolationStartDate: Date? { isolationSymptomsStartDate ?? isolationPositiveTestingDate }
    private var positiveCaseIsolationEndDate: Date? {
        guard let startDate = positiveCaseIsolationStartDate else { return nil }
        let date: Date = startDate.addingTimeInterval(ParametersManager.shared.isolationDuration)
        return date.roundingToBeginningOfDay()
    }
    var isPositiveCaseIsolationEnded: Bool? {
        guard let date = positiveCaseIsolationEndDate else { return nil }
        return Date() >= date
    }
    private var positiveCasePostIsolationEndDate: Date? {
        guard let startDate = positiveCaseIsolationStartDate else { return nil }
        let date: Date = startDate.addingTimeInterval(ParametersManager.shared.isolationDuration + ParametersManager.shared.postIsolationDuration)
        return date.roundingToBeginningOfDay()
    }
    private var isPositiveCasePostIsolationEnded: Bool? {
        guard let date = positiveCasePostIsolationEndDate else { return nil }
        return Date() >= date
    }
    
    // MARK: - Public methods -
    func start(storageManager: StorageManager) {
        self.storageManager = storageManager
    }
    
    func updateState(_ state: State) {
        canTriggerUpdateNotif = false
        resetData()
        isolationState = state.rawValue
        prefillNeededInfoFor(state: state)
        canTriggerUpdateNotif = true
        notifyObservers()
    }
    
    func updateStateBasedOnAppMainStateIfNeeded() {
        guard currentState == nil else { return }
        var state: State? = nil
        if RBManager.shared.isSick {
            state = .positiveCase
        } else if RBManager.shared.isAtRisk || VenuesManager.shared.isAtWarningRisk {
            state = .contactCase
        }
        guard let matchingState = state else { return }
        updateState(matchingState)
    }
    
    func showSymptomsAlert(on controller: UIViewController, okHandler: @escaping () -> ()) {
        let alertController: UIAlertController = UIAlertController(title: "isolation.symptoms.alert.title".localized,
                                                                   message: "isolation.symptoms.alert.message".localized,
                                                                   preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "isolation.symptoms.alert.yes".localized, style: .default, handler: { _ in
            okHandler()
        }))
        alertController.addAction(UIAlertAction(title: "isolation.symptoms.alert.no".localized, style: .default))
        alertController.addAction(UIAlertAction(title: "isolation.symptoms.alert.readMore".localized, style: .default, handler: { _ in
            URL(string: "myHealthController.covidAdvices.url".localized)?.openInSafari()
        }))
        controller.present(alertController, animated: true, completion: nil)
    }
    
    func updateLastContactDate(_ date: Date, notifyChange: Bool) {
        if !notifyChange {
            canTriggerUpdateNotif = false
        }
        isolationLastContactDate = date
        if !notifyChange {
            canTriggerUpdateNotif = true
        }
    }
    
    func setIsKnownIndexAtHome(_ isAtHome: Bool) {
        isolationIsKnownIndexAtHome = isAtHome
    }
    
    func setKnowsIndexSymptomsEndDate(_ knows: Bool) {
        isolationKnowsIndexSymptomsEndDate = knows
    }
    
    func updateIndexSymptomsEndDate(_ date: Date, notifyChange: Bool) {
        if !notifyChange {
            canTriggerUpdateNotif = false
        }
        isolationIndexSymptomsEndDate = date
        if !notifyChange {
            canTriggerUpdateNotif = true
        }
    }
    
    func setNegativeTest() {
        isolationIsTestNegative = true
    }
    
    func updatePositiveTestingDate(_ date: Date, notifyChange: Bool) {
        if !notifyChange {
            canTriggerUpdateNotif = false
        }
        isolationPositiveTestingDate = date
        if !notifyChange {
            canTriggerUpdateNotif = true
        }
    }
    
    func setIsHavingSymptoms(_ havingSymptoms: Bool) {
        isolationIsHavingSymptoms = havingSymptoms
    }
    
    func updateSymptomsStartDate(_ date: Date, notifyChange: Bool) {
        if !notifyChange {
            canTriggerUpdateNotif = false
        }
        isolationSymptomsStartDate = date
        if !notifyChange {
            canTriggerUpdateNotif = true
        }
    }
    
    func setStillHavingFever(_ stillHavingFever: Bool) {
        isolationIsStillHavingFever = stillHavingFever
    }
    
    func setFeverReminderScheduled() {
        isolationIsFeverReminderScheduled = true
    }
    
    func resetData() {
        let wasUpdateNotifAllowed: Bool = canTriggerUpdateNotif
        canTriggerUpdateNotif = false
        
        isolationState = nil
        isolationLastContactDate = nil
        isolationIsKnownIndexAtHome = nil
        isolationKnowsIndexSymptomsEndDate = nil
        isolationIndexSymptomsEndDate = nil
        isolationIsTestNegative = nil
        isolationPositiveTestingDate = nil
        isolationIsHavingSymptoms = nil
        isolationSymptomsStartDate = nil
        isolationIsStillHavingFever = nil
        isolationIsFeverReminderScheduled = nil
        NotificationsManager.shared.cancelStillHavingFeverNotification()
        
        if wasUpdateNotifAllowed {
            canTriggerUpdateNotif = true
            notifyObservers()
        }
    }
    
    // MARK: - Private methods -
    private func prefillNeededInfoFor(state: State) {
        switch state {
        case .positiveCase:
            isolationPositiveTestingDate = RBManager.shared.reportPositiveTestDate
            isolationSymptomsStartDate = RBManager.shared.reportSymptomsStartDate
            if isolationSymptomsStartDate != nil {
                isolationIsHavingSymptoms = true
            } else if isolationPositiveTestingDate != nil {
                isolationIsHavingSymptoms = false
            }
        default:
            break
        }
    }
    
    // MARK: - State calculation methods -
    private func calculateRecommendationState() -> RecommendationState {
        guard let state = currentState else { return calculateInitialCase() }
        
        var recommendationState: RecommendationState = .indeterminate
        switch state {
        case .allGood:
            recommendationState = .allGood
        case .symptoms:
            recommendationState = calculateSymptomsRecommendationState()
        case .contactCase:
            recommendationState = calculateContactCaseRecommendationState()
        case .positiveCase:
            recommendationState = calculatePositiveCaseRecommendationState()
        }
        
        return recommendationState
    }
    
    private func calculateInitialCase() -> RecommendationState {
        let isAtRisk: Bool = RBManager.shared.isAtRisk
        let isAtWarningRisk: Bool = VenuesManager.shared.lastWarningRiskReceivedDate != nil
        let isSick: Bool = RBManager.shared.isSick
        return isAtRisk || isAtWarningRisk || isSick ? .initialCaseAtRiskOrSick : .initialCaseSafe
    }
    
    private func calculateSymptomsRecommendationState() -> RecommendationState {
        var recommendationState: RecommendationState = .indeterminate
        if isolationIsTestNegative == nil {
            recommendationState = .symptoms
        } else {
            recommendationState = .symptomsTested
        }
        return recommendationState
    }
    
    private func calculateContactCaseRecommendationState() -> RecommendationState {
        var recommendationState: RecommendationState = .indeterminate
        
        if isolationIsKnownIndexAtHome == false {
            if isolationIsTestNegative == nil {
                recommendationState = .contactCaseUnknownIndex
            } else {
                if let isContactCasePostIsolationEnded = isContactCasePostIsolationEnded {
                    recommendationState = isContactCasePostIsolationEnded ? calculateInitialCase() : .contactCasePostIsolationPeriod
                }
            }
        } else if isolationIsKnownIndexAtHome == true {
            if isolationIsTestNegative == nil {
                recommendationState = .contactCaseKnownIndexNotTested
            } else {
                if let knowsIndexSymptomsEndDate = isolationKnowsIndexSymptomsEndDate {
                    if knowsIndexSymptomsEndDate {
                        if let isContactCaseIsolationEnded = isContactCaseIsolationEnded, isolationIndexSymptomsEndDate != nil {
                            if isContactCaseIsolationEnded {
                                if let isContactCasePostIsolationEnded = isContactCasePostIsolationEnded {
                                    recommendationState = isContactCasePostIsolationEnded ? calculateInitialCase() : .contactCasePostIsolationPeriod
                                }
                            } else {
                                recommendationState = .contactCaseKnownIndexTestedKnownDate
                            }
                        }
                    } else {
                        recommendationState = .contactCaseKnownIndexTestedUnknownDate
                    }
                }
            }
        }
        
        return recommendationState
    }
    
    private func calculatePositiveCaseRecommendationState() -> RecommendationState {
        var recommendationState: RecommendationState = .indeterminate
        guard let isolationIsHavingSymptoms = isolationIsHavingSymptoms else { return recommendationState }
        guard let isPositiveCaseIsolationEnded = isPositiveCaseIsolationEnded else { return recommendationState }
        
        if isolationIsHavingSymptoms {
            guard isolationSymptomsStartDate != nil else { return recommendationState }
            if isPositiveCaseIsolationEnded {
                if let isolationIsStillHavingFever = isolationIsStillHavingFever {
                    if isolationIsStillHavingFever {
                        recommendationState = .positiveCaseSymptomsAfterIsolationStillHavingFever
                    } else {
                        if let isPositiveCasePostIsolationEnded = isPositiveCasePostIsolationEnded {
                            recommendationState = isPositiveCasePostIsolationEnded ? calculateInitialCase() : .positiveCasePostIsolationPeriod
                        }
                    }
                } else {
                    recommendationState = .positiveCaseSymptomsAfterIsolation
                }
            } else {
                recommendationState = .positiveCaseSymptomsDuringIsolation
            }
        } else {
            if isPositiveCaseIsolationEnded {
                if let isPositiveCasePostIsolationEnded = isPositiveCasePostIsolationEnded {
                    recommendationState = isPositiveCasePostIsolationEnded ? calculateInitialCase() : .positiveCasePostIsolationPeriod
                }
            } else {
                recommendationState = .positiveCaseNoSymptoms
            }
        }
        
        return recommendationState
    }
    
}

// MARK: - States enums -
extension IsolationManager {

    enum State: String, CaseIterable {
        case allGood
        case symptoms
        case contactCase
        case positiveCase
    }

    enum RecommendationState: String, CaseIterable {
        case initialCaseSafe
        case initialCaseAtRiskOrSick
        case allGood
        case symptoms
        case symptomsTested
        case contactCaseUnknownIndex
        case contactCaseKnownIndexNotTested
        case contactCaseKnownIndexTestedKnownDate
        case contactCaseKnownIndexTestedUnknownDate
        case contactCasePostIsolationPeriod
        case positiveCaseNoSymptoms
        case positiveCaseSymptomsDuringIsolation
        case positiveCaseSymptomsAfterIsolation
        case positiveCaseSymptomsAfterIsolationStillHavingFever
        case positiveCasePostIsolationPeriod
        case indeterminate

        var isInitialCase: Bool { [.initialCaseSafe, .initialCaseAtRiskOrSick].contains(self) }
        var isInitialSafeCase: Bool { self == .initialCaseSafe }
        
        var isContactCase: Bool { rawValue.hasPrefix("contactCase") }
        var isPositiveCase: Bool { rawValue.hasPrefix("positiveCase") }

    }

}

extension IsolationManager {
    
    func addObserver(_ observer: IsolationChangesObserver) {
        guard observerWrapper(for: observer) == nil else { return }
        observers.append(IsolationObserverWrapper(observer: observer))
    }
    
    func removeObserver(_ observer: IsolationChangesObserver) {
        guard let wrapper = observerWrapper(for: observer), let index = observers.firstIndex(of: wrapper) else { return }
        observers.remove(at: index)
    }
    
    private func observerWrapper(for observer: IsolationChangesObserver) -> IsolationObserverWrapper? {
        observers.first { $0.observer === observer }
    }
    
    private func notifyObservers() {
        observers.forEach { $0.observer?.isolationDidUpdate() }
    }
    
}
