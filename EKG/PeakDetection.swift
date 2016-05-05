//
//  PeakDetection.swift
//  EKG
//
//  Created by Jack Ross on 5/2/16.
//  Copyright © 2016 Jack Ross. All rights reserved.
//


class PeakDetection: NSObject {

    // properties
    var valueDataBins = [Double]()
    var velocityDataBins = [Double]()
    private var deltaX: Double
    private var binSizeSeconds: Double
    private var binSizeN: Int
    
    private struct Parameters {
        static let movingAveragePeriod = 5 // Seconds
    }
    
    
    // for live processing
    private var currentBin = [Double]()
    var meanValue = 0.0
    var meanVelocity = 0.0
    var movingMeanVelocity = 0.0
    
    
    /*******************************/
    //  MARK: Initializations
    /*******************************/
    
    init(deltaX: Double, binSizeSeconds: Double?) {
        
        self.deltaX = deltaX
        self.binSizeSeconds = binSizeSeconds ?? 0.1
        self.binSizeN = Int(self.binSizeSeconds/self.deltaX)
        
        super.init()
    }
    
    convenience init(initialData: [Double], deltaX: Double, binSizeSeconds: Double?) {
        self.init(deltaX: deltaX, binSizeSeconds: binSizeSeconds)
        
        for i in 0..<initialData.count {
            addDataPoint(initialData[i])
        }
    }
    
    func addDataPoint(value: Double) {
        // add value to currentBin
        // IF   bin is full, calculate average and add to dataBins
        //      and update moving average
        
        currentBin.append(value)
        
        // if bin is full, calculate average and clear
        if currentBin.count == binSizeN {
            updateBinsAndValues()
        }
    }
    
    private func updateBinsAndValues() {
        
        // add average of bin to value array
        let averageOfDataBins = calculateAverage(currentBin)
        valueDataBins.append(averageOfDataBins)
        meanValue = calculateAverage(valueDataBins)
        
        // calculate average derivative over dataBin
        let averageVelocityOfDataBins = calculateMeanVelocity(currentBin)
        velocityDataBins.append(averageVelocityOfDataBins)
        meanVelocity = calculateMeanVelocity(velocityDataBins)
        
        currentBin.removeAll(keepCapacity: false)
        
        if valueDataBins.count > 500 {
            valueDataBins.removeFirst()
        }
        
        if velocityDataBins.count > 500 {
            velocityDataBins.removeFirst()
        }
        
    }
    
    private func calculateMeanVelocity(data: [Double]) -> Double {

        var velocities = [Double]()
        
        var instantVelocity = 0.0
        for i in 1..<data.count {
            instantVelocity = data[i] - data[i - 1]
            velocities.append(instantVelocity)
        }
        
        let averageVelocity = velocities.reduce(0.0, combine: +) / Double(velocities.count)
        
        return averageVelocity
    }
    
    private func calculateAverage(data: [Double]) -> Double {
        
        let average = data.reduce(0.0, combine: +) / Double(data.count)
        return average
    }
    
    
}
