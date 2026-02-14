//
//  NotificationService.swift
//  DF868w
//
//  Ledgerly - Local notification for daily reminder
//

import Foundation
import UserNotifications

@Observable
final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(at time: Date) {
        center.removePendingNotificationRequests(withIdentifiers: ["ledgerly_daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Ledgerly"
        content.body = "Take 10 seconds to log your money for today."
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "ledgerly_daily_reminder", content: content, trigger: trigger)
        center.add(request)
    }

    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["ledgerly_daily_reminder"])
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
}
