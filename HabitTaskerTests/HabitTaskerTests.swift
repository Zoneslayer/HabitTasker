//
//  HabitTaskerTests.swift
//  HabitTaskerTests
//
//  Created by Дмитрий Дубовой on 17.01.2026.
//

import Foundation
import Testing
@testable import HabitTasker

struct HabitTaskerTests {

    @Test func dailyTimeComponentsUsesHourAndMinute() async throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1, hour: 19, minute: 30))!
        let components = NotificationManager.dailyTimeComponents(from: date, calendar: calendar)

        #expect(components.hour == 19)
        #expect(components.minute == 30)
    }

}
