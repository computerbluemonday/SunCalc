//
//  suncalc.swift
//  suncalc
//
//  Created by Shaun Meredith on 10/2/14.
//

import Foundation

// swiftlint:disable identifier_name

public class SunCalc {
	let J0: Double = 0.0009

	public var sunrise: Date?
	public var sunriseEnd: Date?
	public var goldenHourEnd: Date?
	public var solarNoon: Date?
	public var goldenHour: Date?
	public var sunsetStart: Date?
	public var sunset: Date?
	public var dusk: Date?
	public var nauticalDusk: Date?
	public var night: Date?
	public var nadir: Date?
	public var nightEnd: Date?
	public var nauticalDawn: Date?
	public var dawn: Date?

	// swiftlint:disable:next function_parameter_count
	class func getSetJ(h: Double, phi: Double, dec: Double, lw: Double, n: Double, M: Double, L: Double) -> Double {
        let w: Double = TimeUtils.getHourAngle(h: h, phi: phi, d: dec)
        let a: Double = TimeUtils.getApproxTransit(ht: w, lw: lw, n: n)

        return TimeUtils.getSolarTransitJ(ds: a, M: M, L: L)
	}

	public class func getTimes(date: Date, latitude: Double, longitude: Double) -> SunCalc {
		return SunCalc(date: date, latitude: latitude, longitude: longitude)
	}

	public class func getSunPosition(timeAndDate: Date, latitude: Double, longitude: Double) -> SunPosition {
		let lw: Double = Constants.RAD() * -longitude
		let phi: Double = Constants.RAD() * latitude
        let d: Double = DateUtils.toDays(date: timeAndDate)

        let c: EquatorialCoordinates = SunUtils.getSunCoords(d: d)
        let H: Double = PositionUtils.getSiderealTime(d: d, lw: lw) - c.rightAscension

		let azimuth = PositionUtils.getAzimuth(h: H, phi: phi, dec: c.declination)
		let altitude = PositionUtils.getAltitude(h: H, phi: phi, dec: c.declination)
		return SunPosition(azimuth: azimuth, altitude: altitude)
	}

	public class func getMoonPosition(timeAndDate: Date, latitude: Double, longitude: Double) -> MoonPosition {
		let lw: Double = Constants.RAD() * -longitude
		let phi: Double = Constants.RAD() * latitude
        let d: Double = DateUtils.toDays(date: timeAndDate)

        let c: GeocentricCoordinates = MoonUtils.getMoonCoords(d: d)
        let H: Double = PositionUtils.getSiderealTime(d: d, lw: lw) - c.rightAscension
        var h: Double = PositionUtils.getAltitude(h: H, phi: phi, dec: c.declination)

		// altitude correction for refraction
		h += Constants.RAD() * 0.017 / tan(h + Constants.RAD() * 10.26 / (h + Constants.RAD() * 5.10))

		let azimuth = PositionUtils.getAzimuth(h: H, phi: phi, dec: c.declination)
        
        // formula 14.1 of "Astronomical Algorithms" 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
        let pa = atan2(sin(H), (tan(phi) * cos(c.declination) - sin(c.declination) * cos(H)))
        
        return MoonPosition(azimuth: azimuth, altitude: h, distance: c.distance, parallacticAngle: pa)
	}

	public class func getMoonIllumination(timeAndDate: Date) -> MoonIllumination {
        let d: Double = DateUtils.toDays(date: timeAndDate)
        let s: EquatorialCoordinates = SunUtils.getSunCoords(d: d)
        let m: GeocentricCoordinates = MoonUtils.getMoonCoords(d: d)

		let sdist: Double = 149598000 // distance from Earth to Sun in km

		let phi = acos(sin(s.declination) * sin(m.declination)
					   + cos(s.declination) * cos(m.declination) * cos(s.rightAscension - m.rightAscension))
		let inc = atan2(sdist * sin(phi), m.distance - sdist * cos(phi))
		let angle = atan2(
			cos(s.declination) * sin(s.rightAscension - m.rightAscension),
			sin(s.declination) * cos(m.declination)
				- cos(s.declination) * sin(m.declination) * cos(s.rightAscension - m.rightAscension))

		let fraction: Double = (1 + cos(inc)) / 2
		let phase: Double = 0.5 + 0.5 * inc * (angle < 0 ? -1 : 1) / Constants.PI()

		return MoonIllumination(fraction: fraction, phase: phase, angle: angle)
	}

	// swiftlint:disable cyclomatic_complexity
	// swiftlint:disable:next function_body_length
    public class func getMoonTimes(date: Date, latitude: Double, longitude: Double) -> MoonTimes {
        let hc: Double = 0.133 * Constants.RAD()
        var h0: Double = SunCalc.getMoonPosition(
			timeAndDate: date,
			latitude: latitude,
			longitude: longitude).altitude - hc
        var h1: Double = 0
		var h2: Double = 0
		var rise: Double = 0
		var set: Double = 0
		var a: Double = 0
		var b: Double = 0
		var xe: Double = 0
		var ye: Double = 0
		var d: Double = 0
		var roots: Double = 0
		var x1: Double = 0
		var x2: Double = 0
		var dx: Double = 0

        // go in 2-hour chunks, each time seeing if a 3-point quadratic curve crosses zero (which means rise or set)
        for i in stride(from: 1, through: 24, by: 2) {
			let date1 = DateUtils.getHoursLater(date: date, hours: Double(i))!
            h1 = SunCalc.getMoonPosition(timeAndDate: date1, latitude: latitude, longitude: longitude).altitude - hc
			let date2 = DateUtils.getHoursLater(date: date, hours: Double(i + 1))!
            h2 = SunCalc.getMoonPosition(timeAndDate: date2, latitude: latitude, longitude: longitude).altitude - hc
            a = (h0 + h2) / 2 - h1
            b = (h2 - h0) / 2
            xe = -b / (2 * a)
            ye = (a * xe + b) * xe + h1
            d = b * b - 4 * a * h1
            roots = 0

            if d >= 0 {
                dx = sqrt(d) / (abs(a) * 2)
                x1 = xe - dx
                x2 = xe + dx
                if abs(x1) <= 1 {
                    roots += 1
                }
                if abs(x2) <= 1 {
                    roots += 1
                }
                if x1 < -1 {
                    x1 = x2
                }
            }

            if roots == 1 {
                if h0 < 0 {
                    rise = Double(i) + x1
                } else {
                    set = Double(i) + x1
                }
            } else if roots == 2 {
                rise = Double(i) + (ye < 0 ? x2 : x1)
                set = Double(i) + (ye < 0 ? x1 : x2)
            }

            if (rise != 0) && (set != 0) {
                break
            }
            h0 = h2
        }

		var alwaysUp = false
		var alwaysDown = false
		var riseDate: Date?
		var setDate: Date?
        if rise != 0 {
			riseDate = DateUtils.getHoursLater(date: date, hours: rise)
        }
        if set != 0 {
			setDate = DateUtils.getHoursLater(date: date, hours: set)
        }
        if (rise == 0) && (set == 0) {
			if ye > 0 {
				alwaysUp = true
			} else {
				alwaysDown = true
			}
        }

        return MoonTimes(rise: riseDate, set: setDate, alwaysUp: alwaysUp, alwaysDown: alwaysDown)
    }
	// swiftlint:enable cyclomatic_complexity

	init(date: Date, latitude: Double, longitude: Double) {
		let lw: Double = Constants.RAD() * -longitude
		let phi: Double = Constants.RAD() * latitude
        let d: Double = DateUtils.toDays(date: date)

        let n: Double = TimeUtils.getJulianCycle(d: d, lw: lw)
        let ds: Double = TimeUtils.getApproxTransit(ht: 0, lw: lw, n: n)

        let M: Double = SunUtils.getSolarMeanAnomaly(d: ds)
        let L: Double = SunUtils.getEclipticLongitudeM(M: M)
        let dec: Double = PositionUtils.getDeclination(l: L, b: 0)

        let Jnoon: Double = TimeUtils.getSolarTransitJ(ds: ds, M: M, L: L)

        self.solarNoon = DateUtils.fromJulian(j: Jnoon)
        self.nadir = DateUtils.fromJulian(j: Jnoon - 0.5)

		// sun times configuration (angle, morning name, evening name)
		// unrolled the loop working on this data:
		// var times = [
		//             [-0.83, 'sunrise',       'sunset'      ],
		//             [ -0.3, 'sunriseEnd',    'sunsetStart' ],
		//             [   -6, 'dawn',          'dusk'        ],
		//             [  -12, 'nauticalDawn',  'nauticalDusk'],
		//             [  -18, 'nightEnd',      'night'       ],
		//             [    6, 'goldenHourEnd', 'goldenHour'  ]
		//             ];

		var h: Double = -0.83
        var Jset: Double = SunCalc.getSetJ(h: h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		var Jrise: Double = Jnoon - (Jset - Jnoon)

        self.sunrise = DateUtils.fromJulian(j: Jrise)
        self.sunset = DateUtils.fromJulian(j: Jset)

		h = -0.3
        Jset = SunCalc.getSetJ(h: h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
        self.sunriseEnd = DateUtils.fromJulian(j: Jrise)
        self.sunsetStart = DateUtils.fromJulian(j: Jset)

		h = -6
        Jset = SunCalc.getSetJ(h: h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
        self.dawn = DateUtils.fromJulian(j: Jrise)
        self.dusk = DateUtils.fromJulian(j: Jset)

		h = -12
        Jset = SunCalc.getSetJ(h: h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
        self.nauticalDawn = DateUtils.fromJulian(j: Jrise)
        self.nauticalDusk = DateUtils.fromJulian(j: Jset)

		h = -18
        Jset = SunCalc.getSetJ(h: h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
        self.nightEnd = DateUtils.fromJulian(j: Jrise)
        self.night = DateUtils.fromJulian(j: Jset)

		h = 6
        Jset = SunCalc.getSetJ(h: h * Constants.RAD(), phi: phi, dec: dec, lw: lw, n: n, M: M, L: L)
		Jrise = Jnoon - (Jset - Jnoon)
        self.goldenHourEnd = DateUtils.fromJulian(j: Jrise)
        self.goldenHour = DateUtils.fromJulian(j: Jset)

	}
}

// swiftlint:enable identifier_name
