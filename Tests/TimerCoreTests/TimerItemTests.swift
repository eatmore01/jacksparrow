import Testing
import Foundation
@testable import TimerCore

private let t0 = Date(timeIntervalSince1970: 1_000_000)

private func makeItem(minutes: Int = 40) -> TimerItem {
    TimerItem(title: "Do X", minutes: minutes)
}

@Test func idleShowsFullDuration() {
    let item = makeItem()
    #expect(item.remaining(at: t0) == 2400)
    #expect(item.pendingAction == .start)
    #expect(item.stopsUsed == 0)
}

@Test func startThenCountsDownFromWallClock() {
    var item = makeItem()
    item.primaryAction(now: t0)
    #expect(item.isRunning)
    #expect(item.remaining(at: t0) == 2400)
    #expect(item.remaining(at: t0.addingTimeInterval(60)) == 2340)
}

@Test func firstStopIncrementsCounterAndFreezesRemaining() {
    var item = makeItem()
    item.primaryAction(now: t0)
    item.primaryAction(now: t0.addingTimeInterval(100))
    #expect(item.stopsUsed == 1)
    #expect(item.state == .paused(remaining: 2300))
    #expect(item.remaining(at: t0.addingTimeInterval(9999)) == 2300)
}

@Test func resumeDoesNotIncrementCounter() {
    var item = makeItem()
    item.primaryAction(now: t0)
    item.primaryAction(now: t0.addingTimeInterval(100))
    item.primaryAction(now: t0.addingTimeInterval(500))
    #expect(item.stopsUsed == 1)
    #expect(item.isRunning)
    #expect(item.remaining(at: t0.addingTimeInterval(500)) == 2300)
    #expect(item.remaining(at: t0.addingTimeInterval(560)) == 2240)
}

@Test func secondStopReachesLimitAndTurnsNextPressIntoReset() {
    var item = makeItem()
    item.primaryAction(now: t0)
    item.primaryAction(now: t0.addingTimeInterval(10))
    item.primaryAction(now: t0.addingTimeInterval(20))
    item.primaryAction(now: t0.addingTimeInterval(30))
    #expect(item.stopsUsed == 2)
    #expect(item.stopsRemaining == 0)
    #expect(item.state == .paused(remaining: 2380))
    #expect(item.pendingAction == .resume)

    item.primaryAction(now: t0.addingTimeInterval(40))
    #expect(item.isRunning)
    #expect(item.stopsUsed == 2)
    #expect(item.pendingAction == .resetAfterLimit)
}

@Test func thirdStopResetsToFullDurationAndZeroesCounter() {
    var item = makeItem()
    for offset in [0, 10, 20, 30, 40] {
        item.primaryAction(now: t0.addingTimeInterval(TimeInterval(offset)))
    }
    #expect(item.isRunning)
    #expect(item.stopsUsed == 2)

    item.primaryAction(now: t0.addingTimeInterval(50))
    #expect(item.state == .idle)
    #expect(item.stopsUsed == 0)
    #expect(item.remaining(at: t0.addingTimeInterval(50)) == 2400)
    #expect(item.pendingAction == .start)
}

@Test func tickFinishesAtZeroAndNeverGoesNegative() {
    var item = makeItem(minutes: 1)
    item.primaryAction(now: t0)
    item.tick(now: t0.addingTimeInterval(59))
    #expect(item.isRunning)
    item.tick(now: t0.addingTimeInterval(60))
    #expect(item.state == .finished)
    #expect(item.remaining(at: t0.addingTimeInterval(600)) == 0)
}

@Test func finishedResetsBackToIdle() {
    var item = makeItem(minutes: 1)
    item.primaryAction(now: t0)
    item.tick(now: t0.addingTimeInterval(120))
    #expect(item.pendingAction == .resetAfterFinish)
    item.primaryAction(now: t0.addingTimeInterval(120))
    #expect(item.state == .idle)
    #expect(item.stopsUsed == 0)
    #expect(item.remaining(at: t0.addingTimeInterval(120)) == 60)
}

@Test func pausedWithExhaustedStopsStillResumes() {
    var item = TimerItem(title: "x", minutes: 10, state: .paused(remaining: 300), stopsUsed: 2)
    #expect(item.pendingAction == .resume)
    item.primaryAction(now: t0)
    #expect(item.isRunning)
    #expect(item.stopsUsed == 2)
    #expect(item.pendingAction == .resetAfterLimit)
}

@Test func resumingAnAlreadyElapsedPauseFinishes() {
    var item = TimerItem(title: "x", minutes: 10, state: .paused(remaining: 0), stopsUsed: 1)
    item.primaryAction(now: t0)
    #expect(item.state == .finished)
}

@Test func formatsUnderAnHourAsMinutesSeconds() {
    #expect(formatRemaining(2400) == "40:00")
    #expect(formatRemaining(59) == "00:59")
    #expect(formatRemaining(0) == "00:00")
    #expect(formatRemaining(-5) == "00:00")
}

@Test func formatsOverAnHourWithHours() {
    #expect(formatRemaining(3600) == "1:00:00")
    #expect(formatRemaining(3661) == "1:01:01")
    #expect(formatRemaining(86_399) == "23:59:59")
}

@Test func formatRoundsUpSoZeroShowsOnlyAtTheEnd() {
    #expect(formatRemaining(2399.5) == "40:00")
    #expect(formatRemaining(0.2) == "00:01")
}

@Test func durationFromHoursAndMinutes() {
    #expect(durationSeconds(hours: 0, minutes: 40) == 2400)
    #expect(durationSeconds(hours: 1, minutes: 30) == 5400)
    #expect(durationSeconds(hours: -1, minutes: -5) == 0)
}

@Test func pressingBetweenZeroAndNextTickResetsInsteadOfBurningAStop() {
    var item = makeItem(minutes: 1)
    item.primaryAction(now: t0)
    item.primaryAction(now: t0.addingTimeInterval(60))
    #expect(item.state == .idle)
    #expect(item.stopsUsed == 0)
    #expect(item.remaining(at: t0.addingTimeInterval(60)) == 60)
}

@Test func hoursAndMinutesCombineIntoDuration() {
    let item = TimerItem(title: "Do X", hours: 2, minutes: 30)
    #expect(item.duration == 9000)
    #expect(formatRemaining(item.remaining(at: t0)) == "2:30:00")
}

@Test func constructorClampsMinutesAboveSixty() {
    let item = TimerItem(title: "Do X", minutes: 70)
    #expect(item.minutes == 60)
    #expect(item.duration == 3600)
}

@Test func constructorClampsNegativeInputToZero() {
    let item = TimerItem(title: "Do X", hours: -3, minutes: -5)
    #expect(item.hours == 0)
    #expect(item.minutes == 0)
    #expect(item.duration == 0)
}

@Test func constructorClampsHoursAboveTwentyThree() {
    let item = TimerItem(title: "Do X", hours: 99, minutes: 10)
    #expect(item.hours == 23)
}

@Test func clampHelpersCoverTheWholeRange() {
    #expect(TimerItem.clampMinutes(70) == 60)
    #expect(TimerItem.clampMinutes(60) == 60)
    #expect(TimerItem.clampMinutes(0) == 0)
    #expect(TimerItem.clampMinutes(-5) == 0)
    #expect(TimerItem.clampMinutes(37) == 37)
    #expect(TimerItem.clampHours(-1) == 0)
    #expect(TimerItem.clampHours(24) == 23)
    #expect(TimerItem.clampHours(7) == 7)
}

@Test func zeroMinuteTimerFinishesAsSoonAsItStarts() {
    var item = TimerItem(title: "Do X", minutes: 0)
    #expect(item.duration == 0)
    item.primaryAction(now: t0)
    #expect(item.state == .finished)
}
