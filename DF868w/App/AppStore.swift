//
//  AppStore.swift
//  DF868w
//
//  Ledgerly - Shared app state and dependency injection
//

import SwiftUI
import SwiftData

@Observable
final class AppStore {
    var toastMessage: ToastMessage?
    var showToast = false
    var isOnboardingComplete = false

    let transactionService: TransactionService
    let budgetService: BudgetService
    let chartDataBuilder: ChartDataBuilder
    let exportImportService: ExportImportService
    let notificationService: NotificationService

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let txService = TransactionService(modelContext: modelContext)
        self.transactionService = txService
        self.budgetService = BudgetService(modelContext: modelContext, transactionService: txService)
        self.chartDataBuilder = ChartDataBuilder(transactionService: txService, modelContext: modelContext)
        self.exportImportService = ExportImportService(modelContext: modelContext)
        self.notificationService = NotificationService()
    }

    func showSuccessToast(_ text: String) {
        toastMessage = .success(text)
        withAnimation(.easeInOut(duration: 0.3)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation {
                self?.showToast = false
            }
        }
    }
}