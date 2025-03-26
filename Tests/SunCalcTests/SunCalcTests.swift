//
//  SunCalcTests.swift
//
//  Created by Alexandre Colucci on 09.05.22
//

import XCTest
@testable import SunCalc

final class SunCalcTests: XCTestCase {

	var date: Date = Date()
	var LAT: Double = 50.5
	var LNG: Double = 30.5
	let NEARNESS = 1e-9

	override func setUpWithError() throws {
		var calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
		calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let components: DateComponents = DateComponents(year: 2013, month: 3, day: 5)

        self.date = calendar.date(from: components)!
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_sun_getTimes() {
        let sunCalc = SunCalc.getTimes(date: date, latitude: LAT, longitude: LNG)

		let formatter: DateFormatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		formatter.timeZone = TimeZone(abbreviation: "GMT")

        XCTAssertEqual(formatter.string(from: sunCalc.solarNoon!), "2013-03-05T10:10:57Z")
		XCTAssertEqual(formatter.string(from: sunCalc.nadir!), "2013-03-04T22:10:57Z")
		XCTAssertEqual(formatter.string(from: sunCalc.sunrise!), "2013-03-05T04:34:57Z")
		XCTAssertEqual(formatter.string(from: sunCalc.sunset!), "2013-03-05T15:46:56Z")
		XCTAssertEqual(formatter.string(from: sunCalc.sunriseEnd!), "2013-03-05T04:38:19Z")
		XCTAssertEqual(formatter.string(from: sunCalc.sunsetStart!), "2013-03-05T15:43:34Z")
		XCTAssertEqual(formatter.string(from: sunCalc.dawn!), "2013-03-05T04:02:17Z")
		XCTAssertEqual(formatter.string(from: sunCalc.dusk!), "2013-03-05T16:19:36Z")
		XCTAssertEqual(formatter.string(from: sunCalc.nauticalDawn!), "2013-03-05T03:24:31Z")
		XCTAssertEqual(formatter.string(from: sunCalc.nauticalDusk!), "2013-03-05T16:57:22Z")
		XCTAssertEqual(formatter.string(from: sunCalc.nightEnd!), "2013-03-05T02:46:17Z")
		XCTAssertEqual(formatter.string(from: sunCalc.night!), "2013-03-05T17:35:36Z")
		XCTAssertEqual(formatter.string(from: sunCalc.goldenHourEnd!), "2013-03-05T05:19:01Z")
		XCTAssertEqual(formatter.string(from: sunCalc.goldenHour!), "2013-03-05T15:02:52Z")
	}

	func test_sun_getTimes_invalid() {
		let sunCalc = SunCalc.getTimes(date: date, latitude: 84.0, longitude: 111.0)

		XCTAssertNotEqual(sunCalc.sunrise, nil)
		XCTAssertNotEqual(sunCalc.sunriseEnd, nil)
		XCTAssertNotEqual(sunCalc.sunset, nil)
		XCTAssertNotEqual(sunCalc.sunsetStart, nil)

		XCTAssertEqual(sunCalc.goldenHourEnd, nil)
		XCTAssertEqual(sunCalc.goldenHour, nil)
		XCTAssertEqual(sunCalc.night, nil)
		XCTAssertEqual(sunCalc.nightEnd, nil)
	}

	func test_sun_getPosition() {
        let sunPos: SunPosition = SunCalc.getSunPosition(timeAndDate: date, latitude: LAT, longitude: LNG)
        XCTAssertEqual(sunPos.azimuth, -2.5003175907168385, accuracy: NEARNESS)
        XCTAssertEqual(sunPos.altitude, -0.7000406838781611, accuracy: NEARNESS)
	}

	func test_getMoonPosition() {
        let moonPos: MoonPosition = SunCalc.getMoonPosition(timeAndDate: date, latitude: LAT, longitude: LNG)
        XCTAssertEqual(moonPos.azimuth, -0.9783999522438226, accuracy: NEARNESS)
        XCTAssertEqual(moonPos.altitude, 0.006969727754891917, accuracy: NEARNESS)
        XCTAssertEqual(moonPos.distance, 364121.37256256294, accuracy: NEARNESS)
        XCTAssertEqual(moonPos.parallacticAngle, -0.5983211760526778, accuracy: NEARNESS)
	}

	func test_getMoonIllumination() {
        let moonIllum: MoonIllumination = SunCalc.getMoonIllumination(timeAndDate: date)
        XCTAssertEqual(moonIllum.fraction, 0.4848068202456373, accuracy: NEARNESS)
        XCTAssertEqual(moonIllum.phase, 0.7548368838538762, accuracy: NEARNESS)
        XCTAssertEqual(moonIllum.angle, 1.6732942678578346, accuracy: NEARNESS)
	}

    func test_getMoonTimes() {
        var calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let components: DateComponents = DateComponents(year: 2013, month: 3, day: 4, hour: 0, minute: 0, second: 0)

        let moonTimes: MoonTimes = SunCalc.getMoonTimes(date: calendar.date(from: components)!, latitude: LAT, longitude: LNG)
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss zzz"
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        let rise: Date = formatter.date(from: "Mon, 04 Mar 2013 23:54:29 GMT")!
        let set: Date = formatter.date(from: "Mon, 04 Mar 2013 07:47:58 GMT")!
        let moonRise: Date = moonTimes.rise ?? Date()
        let moonSet: Date = moonTimes.set  ?? Date()
        let slop: Double = 20 * 60  // 20 minutes

        XCTAssertTrue((moonRise >= rise.addingTimeInterval(-1 * slop)) && (moonRise <= rise.addingTimeInterval(slop)))
        // XCTAssertEqual(formatter.string(from: moonTimes.rise ?? Date()),              "Mon, 04 Mar 2013 23:54:29 GMT")
        XCTAssertTrue((moonSet >= set.addingTimeInterval(-1 * slop)) && (moonSet <= set.addingTimeInterval(slop)))
        // XCTAssertEqual(formatter.string(from: moonTimes.set  ?? Date()),              "Mon, 04 Mar 2013 07:47:58 GMT")
    }

	func test_README_example() {
		let date = Date()

		let sunCalc = SunCalc.getTimes(date: date, latitude: 51.5, longitude: -0.1)
		if let sunrise = sunCalc.sunrise {
			debugPrint("sunrise: \(sunrise.formatted())")
		}

		if let sunset = sunCalc.sunset {
			debugPrint("sunset: \(sunset.formatted())")
		}

		let sunPos = SunCalc.getSunPosition(timeAndDate: date, latitude: 51.5, longitude: -0.1)
		let sunriseAzimuth = sunPos.azimuth * 180 / Constants.PI()
		debugPrint("sunriseAzimuth: \(sunriseAzimuth)")
	}
}
