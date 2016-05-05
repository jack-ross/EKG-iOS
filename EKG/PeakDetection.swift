//
//  PeakDetection.swift
//  EKG
//
//  Created by Jack Ross on 5/2/16.
//  Copyright © 2016 Jack Ross. All rights reserved.
//

protocol PeakDetectionDelegate {
    // ** Required **
    func updatedBPM(bpm: Double)
}

class PeakDetection: NSObject {
    
    var delegate: PeakDetectionDelegate!

    // properties
    var valueDataBins = [Double]()
    var peaks = Dictionary<Double, Double>() // dictionary of peak ampl
    private let binSizeN = 5
    private var timePerPeak = 5.0/120 // 1 peak index = 5 peaks, therefor 3*120Hz = 0.0833 seconds per peak index
    private var bufferMaxSize = 120 // 120 bins before calculation
    private let minPeakAmplitude = 520.0 // mV
    private let minPeakTimeDifference = 0.3 // must be 0.5 seconds between peaks

    
    // for live processing
    private var currentBin = [Double]()
    var meanValue = 0.0
    
    
    func addDataPoint(value: Double) {
        // add value to currentBin
        // IF   bin is full, calculate average and add to dataBins
        //      and update moving average
        
        currentBin.append(value)
        
        // if bin is full, calculate average and clear
        if currentBin.count == binSizeN {
            updateBinsAndValues()
            currentBin.removeAll(keepCapacity: false)
        }
    }
    
    private func updateBinsAndValues() {
        
        // add average of bin to value array
        let averageOfDataBins = calculateAverage(currentBin)
        valueDataBins.append(averageOfDataBins)
        
        if valueDataBins.count == bufferMaxSize {
            detectBPM()
            valueDataBins.removeAll(keepCapacity: false)
        }
        
        // get moving mean of last five seconds
        meanValue = calculateAverage(valueDataBins)
    }
    
    func detectBPM() {
        var peaks = peakDetect(valueDataBins)
        
        if peaks.count < 3 {
            return
        }
        var peakTimes = Array(peaks.keys)
        
        for i in 0..<(peakTimes.count-1) {
            
            let leftPeakTime = peakTimes[i]
            let rightPeakTime = peakTimes[i + 1]
            
            let peakTimeDifference = leftPeakTime - rightPeakTime
            
            if peakTimeDifference < minPeakTimeDifference {
                guard let leftPeakAmplitude = peaks[leftPeakTime] else {break}
                guard let rightPeakAmplitude = peaks[rightPeakTime] else { break }
                
                let difference = Double.abs((leftPeakAmplitude - rightPeakAmplitude ))
                
                // select greater of two peaks
                if difference < 15 {
                    peaks.removeValueForKey(leftPeakTime)

                }
                else if rightPeakAmplitude > leftPeakAmplitude {
                    peaks.removeValueForKey(leftPeakTime)
                } else {
                    peaks.removeValueForKey(rightPeakTime)
                }
            }
        }
        
        peakTimes = Array(peaks.keys)
        peakTimes.sortInPlace { (element1, element2) -> Bool in
            return element1 < element2
        }
        
        var averageTimeDifference = [Double]()
        for i in 0..<(peakTimes.count-1) {
            averageTimeDifference.append(peakTimes[i+1] - peakTimes[i])
        }
        let average = averageTimeDifference.reduce(0.0, combine: +) / Double(averageTimeDifference.count)

        delegate.updatedBPM(60.0/average)
        print(peaks.count)
    }
    
    func peakDetect(data: [Double]) -> Dictionary<Double, Double> {
        
        var peaks = Dictionary<Double, Double>()
        
        for i in 1..<(data.count - 1) {
            
            let centerPoint = data[i]
            
            if centerPoint > minPeakAmplitude {
            
                let leftPoint = data[i - 1]
                let rightPoint = data[i + 1]
                
                if isLocalMax(leftPoint, centerPoint: centerPoint, rightPoint: rightPoint) {
                    peaks[Double(i) * timePerPeak] = centerPoint
                }
            }
        }
        
        return peaks
        
    }
    
    func isLocalMax(leftPoint: Double, centerPoint: Double, rightPoint: Double) -> Bool {
        
        if leftPoint < centerPoint && rightPoint < centerPoint {
            return true
        }
        
        return false
    }
    
    private func calculateAverage(data: [Double]) -> Double {
        
        let average = data.reduce(0.0, combine: +) / Double(data.count)
        return average
    }
    
    
}
