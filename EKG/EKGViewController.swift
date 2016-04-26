//
//  ViewController.swift
//  EKG
//
//  Created by Jack Ross on 4/21/16.
//  Copyright © 2016 Jack Ross. All rights reserved.
//

import UIKit
import Charts

class EKGViewController: UIViewController {
    
    
    @IBOutlet weak var lineChartView: LineChartView!
    var months: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "EKG Graph"
        setChartData(Constants.EKGTimes, values: Constants.EKGValues)
        configureChart()
        addLimitLine()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setChartData(dataPoints: [Double], values: [Double]) {
        lineChartView.noDataText = "You need to provide data for the chart."
        
        
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = LineChartDataSet(yVals: dataEntries, label: "mV")
        chartDataSet.circleRadius = 1;
        let chartData = LineChartData(xVals: dataPoints, dataSet: chartDataSet)
        lineChartView.data = chartData
    }
    
    
    func configureChart() {
        lineChartView.backgroundColor = UIColor.whiteColor()
        lineChartView.drawBordersEnabled = false
        lineChartView.leftAxis.drawAxisLineEnabled = false
        lineChartView.rightAxis.drawAxisLineEnabled = false
        lineChartView.xAxis.drawAxisLineEnabled = false
        
        // turn off legend and description
        lineChartView.legend.enabled = false
        lineChartView.descriptionText = ""
        
        // turn off axes
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        
        // turn off grid
        lineChartView.xAxis.drawGridLinesEnabled = false
        lineChartView.leftAxis.drawGridLinesEnabled = false
        lineChartView.rightAxis.drawGridLinesEnabled = false
        
        lineChartView.gridBackgroundColor = NSUIColor.clearColor()
    }
    
    func addLimitLine() {
        let ll = ChartLimitLine(limit: 0, label: "0 Volts")
        ll.lineColor = UIColor.redColor()
        ll.lineWidth = 1
        ll.valueTextColor = UIColor.blackColor()
        
        lineChartView.leftAxis.addLimitLine(ll)
    }


}

