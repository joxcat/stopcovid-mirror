// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  VaccinationController.swift
//  TousAntiCovid
//
//  Created by Lunabee Studio / Date - 12/01/2021 - for the TousAntiCovid project.
//

import UIKit
import PKHUD
import RobertSDK
import StorageSDK
import ServerSDK
import CoreLocation

final class VaccinationController: CVTableViewController {
    
    private let deinitBlock: () -> ()
    private let didTouchWebVaccination: () -> ()

    init(didTouchWebVaccination: @escaping () -> (), deinitBlock: @escaping () -> ()) {
        self.didTouchWebVaccination = didTouchWebVaccination
        self.deinitBlock = deinitBlock

        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Must use the other init method")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateTitle()
        initUI()
        reloadUI()
        addObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func updateTitle() {
        title = "vaccinationController.title".localized
    }
    
    private func initUI() {
        tableView.contentInset.top = navigationChildController?.navigationBarHeight ?? 0.0
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20.0))
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Appearance.Controller.cardTableViewBackgroundColor
        tableView.showsVerticalScrollIndicator = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "common.close".localized, style: .plain, target: self, action: #selector(didTouchCloseButton))
    }
    
    override func createRows() -> [CVRow] {
        eligibilitySectionRows() + locationSectionRows()
    }

    @objc private func didTouchCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    private func addObservers() {
        VaccinationCenterManager.shared.addObserver(self)
        LocalizationsManager.shared.addObserver(self)
    }
    
    private func removeObservers() {
        VaccinationCenterManager.shared.removeObserver(self)
        LocalizationsManager.shared.removeObserver(self)
    }

    // MARK: - Section -
    private func eligibilitySectionRows() -> [CVRow] {
        [elibilitySectionRow(), eligibilityRow()]
    }

    private func locationSectionRows() -> [CVRow] {
        var rows: [CVRow] = [locationSectionRow()]
        if KeyFiguresManager.shared.currentPostalCode == nil {
            rows.append(explanationRow())
        }
        rows.append(postalCodeRow(postalCode: KeyFiguresManager.shared.currentPostalCode))
        guard KeyFiguresManager.shared.currentPostalCode != nil else { return rows }
        if let vaccinationCenters = VaccinationCenterManager.shared.vaccinationCentersToDisplay {
            let vaccinationCenterRows: [CVRow] = vaccinationCenters.map { vaccinationCenter in
                vaccinationCenterRow(vaccinationCenter: vaccinationCenter)
            }
            rows.append(contentsOf: vaccinationCenterRows)
            if vaccinationCenters.isEmpty {
                rows.append(noVaccinationCenterFoundRow())
                rows.append(refreshRow())
            }
        } else {
            let loadingCardCell: CVRow = CVRow(xibName: .loadingCardCell)
            rows.append(loadingCardCell)
        }
        rows.append(footerWithPostalCodeRow())
        rows.append(webVaccinationRow())
        return rows
    }

    //MARK: - Row -
    private func elibilitySectionRow() -> CVRow {
        CVRow(title: "vaccinationController.eligibility.title".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: 30.0,
                                 bottomInset: 10.0,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Section.titleFont }))
    }

    private func eligibilityRow() -> CVRow {
        CVRow(subtitle: "vaccinationController.eligibility.subtitle".localized,
              buttonTitle: "vaccinationController.eligibility.buttonTitle".localized,
              xibName: .paragraphCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: 10.0,
                                 bottomInset: 10.0,
                                 textAlignment: .left),
              selectionAction: {
                URL(string: "vaccinationController.eligibility.url".localized)?.openInSafari()
              })
    }

    private func locationSectionRow() -> CVRow {
        CVRow(title: "vaccinationController.vaccinationLocation.section.title".localized,
              xibName: .textCell,
              theme: CVRow.Theme(topInset: 30.0,
                                 bottomInset: 10.0,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Section.titleFont }))
    }
    
    private func explanationRow() -> CVRow {
        CVRow(subtitle: String(format: "vaccinationController.vaccinationLocation.explanation".localized, ParametersManager.shared.vaccinationCentersCount),
              xibName: .textCell,
              theme: CVRow.Theme(topInset: 10.0,
                                 bottomInset: 10.0,
                                 textAlignment: .natural))
    }

    private func postalCodeRow(postalCode: String?) -> CVRow {
        let title: String = postalCode == nil ? "vaccinationController.vaccinationLocation.newPostalCode".localized : "vaccinationController.vaccinationLocation.updatePostalCode".localized
        let postalCodeRow: CVRow = CVRow(title: title,
                                         image: Asset.Images.location.image,
                                         xibName: .standardCardCell,
                                         theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: 10.0,
                                                             bottomInset: Appearance.Cell.leftMargin,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.standardFont },
                                                             titleColor: Appearance.Cell.Text.headerTitleColor,
                                                             imageTintColor: Appearance.Cell.Text.headerTitleColor),
                                         selectionAction: { [weak self] in
                                            self?.didTouchUpdateLocation()
                                         },
                                         willDisplay: { cell in
                                            cell.selectionStyle = .none
                                            cell.accessoryType = .none
                                         })
        return postalCodeRow
    }
    
    private func refreshRow() -> CVRow {
        let postalCodeRow: CVRow = CVRow(title: "common.tryAgain".localized,
                                         image: Asset.Images.refresh.image,
                                         xibName: .standardCardCell,
                                         theme:  CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                                             topInset: 10.0,
                                                             bottomInset: Appearance.Cell.leftMargin,
                                                             textAlignment: .natural,
                                                             titleFont: { Appearance.Cell.Text.standardFont },
                                                             titleColor: Appearance.Cell.Text.headerTitleColor,
                                                             imageTintColor: Appearance.Cell.Text.headerTitleColor),
                                         selectionAction: { [weak self] in
                                            self?.didTouchRefresh()
                                         },
                                         willDisplay: { cell in
                                            cell.selectionStyle = .none
                                            cell.accessoryType = .none
                                         })
        return postalCodeRow
    }

    private func vaccinationCenterRow(vaccinationCenter: VaccinationCenter) -> CVRow {
        CVRow(title: vaccinationCenter.name,
              subtitle: vaccinationCenter.modalities,
              xibName: .vaccinationCenterCell,
              theme: CVRow.Theme(backgroundColor: Appearance.Cell.cardBackgroundColor,
                                 topInset: 0.0,
                                 bottomInset: Appearance.Cell.leftMargin,
                                 textAlignment: .natural,
                                 titleFont: { Appearance.Cell.Text.titleFont },
                                 titleColor: Appearance.Cell.Text.titleColor,
                                 subtitleFont: { Appearance.Cell.Text.subtitleFont },
                                 subtitleColor: Appearance.Cell.Text.headerTitleColor),
              associatedValue: vaccinationCenter,
              selectionAction: { [weak self] in
                self?.didTouchVaccinationCenter(vaccinationCenter: vaccinationCenter)
              })
    }

    private func noVaccinationCenterFoundRow() -> CVRow {
        CVRow(subtitle: "vaccinationController.vaccinationLocation.vaccinationCenterNotFound".localized,
              xibName: .textCell,
              theme:  CVRow.Theme(topInset: 10.0,
                                  bottomInset: 10.0,
                                  textAlignment: .natural))
    }

    private func webVaccinationRow() -> CVRow {
        CVRow(buttonTitle: "vaccinationController.vaccinationLocation.buttonTitle".localized,
              xibName: .linkButtonCell,
              theme:  CVRow.Theme(topInset: 0.0,
                                  bottomInset: 20.0),
              secondarySelectionAction: { [weak self] in
                self?.didTouchWebVaccination()
              })
    }

    private func footerWithPostalCodeRow() -> CVRow {
        CVRow(title: "vaccinationController.vaccinationLocation.footer".localized,
              xibName: .textCell,
              theme:  CVRow.Theme(topInset: 10.0,
                                  bottomInset: 8.0,
                                  textAlignment: .natural,
                                  titleFont: { Appearance.Cell.Text.footerFont },
                                  titleColor: Appearance.Cell.Text.captionTitleColor))
    }

    // MARK: - Action -
    private func didTouchUpdateLocation() {
        KeyFiguresManager.shared.updateLocation(from: self)
    }
    
    private func didTouchRefresh() {
        VaccinationCenterManager.shared.reloadFiles()
    }

    private func didTouchVaccinationCenter(vaccinationCenter: VaccinationCenter) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: vaccinationCenter.name, preferredStyle: .actionSheet)
        if let phoneNumber = vaccinationCenter.tel, !phoneNumber.isEmpty {
            alertController.addAction(UIAlertAction(title: String(format: "vaccinationController.vaccinationCenter.actionSheet.alert.call".localized, phoneNumber), style: .default, handler: { [weak self] _ in
                self?.didTouchCallVaccinationCenter(phoneNumber: phoneNumber)
            }))
        }

        if let url = vaccinationCenter.url, !url.isEmpty {
            alertController.addAction(UIAlertAction(title: "vaccinationController.vaccinationCenter.actionSheet.alert.website".localized, style: .default, handler: { [weak self] _ in
                self?.didTouchShowVaccinationCenterWebsite(url: url)
            }))
        }

        if let location = vaccinationCenter.location {
            alertController.addAction(UIAlertAction(title: "vaccinationController.vaccinationCenter.actionSheet.alert.mapLocation".localized, style: .default, handler: { [weak self] _ in
                self?.didTouchShowVaccinationCenterLocation(location: location)
            }))
        }

        alertController.addAction(UIAlertAction(title: "vaccinationController.vaccinationCenter.actionSheet.alert.sharing".localized, style: .default, handler: { [weak self] _ in
            self?.didTouchSharingVaccinationCenter(vaccinationCenter: vaccinationCenter)
        }))

        alertController.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        present(alertController, animated: true, completion: nil)
    }

    private func didTouchCallVaccinationCenter(phoneNumber: String) {
        guard let url = URL(string: "tel://\(phoneNumber)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func didTouchShowVaccinationCenterWebsite(url: String) {
        URL(string: url)?.openInSafari()
    }

    private func didTouchShowVaccinationCenterLocation(location: CLLocation) {
        guard let appleMapsUrl = URL(string:"maps://?q=\(location.coordinate.latitude),\(location.coordinate.longitude)") else { return }
        guard let googleMapsUrl = URL(string:"comgooglemaps://?q=\(location.coordinate.latitude),\(location.coordinate.longitude)") else { return }

        if UIApplication.shared.canOpenURL(googleMapsUrl) {
            UIApplication.shared.open(googleMapsUrl)
        } else if UIApplication.shared.canOpenURL(appleMapsUrl) {
            UIApplication.shared.open(appleMapsUrl)
        }
    }

    private func didTouchSharingVaccinationCenter(vaccinationCenter: VaccinationCenter) {
        var sharingTextArray: [String] = []
        let address: String = [vaccinationCenter.name, vaccinationCenter.streetNumber, vaccinationCenter.streetName, "\(vaccinationCenter.postalCode) \(vaccinationCenter.locality)"].filter { !$0.isEmpty } .joined(separator: ", ")
        sharingTextArray.append(address)

        if let phoneNumber = vaccinationCenter.tel, !phoneNumber.isEmpty {
            sharingTextArray.append(String(format:  "vaccinationController.vaccinationCenter.actionSheet.alert.sharing.text.tel".localized, phoneNumber))
        }
        if let url = vaccinationCenter.url, !url.isEmpty {
            sharingTextArray.append(String(format:  "vaccinationController.vaccinationCenter.actionSheet.alert.sharing.text.url".localized, url))
        }
        let activityItems: [Any?] = [sharingTextArray.joined(separator: ". ")]
        let controller: UIActivityViewController = UIActivityViewController(activityItems: activityItems.compactMap { $0 }, applicationActivities: nil)
        controller.excludedActivityTypes = [.saveToCameraRoll, .print]
        present(controller, animated: true, completion: nil)
    }

}

extension VaccinationController: VaccinationCenterChangesObserver {
    func vaccinationCentersDidUpdate() {
        reloadUI()
    }
}

extension VaccinationController: LocalizationsChangesObserver {
    
    func localizationsChanged() {
        updateTitle()
        reloadUI()
    }
    
}
