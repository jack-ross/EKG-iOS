//
//  ViewController.swift
//  EKG
//
//  Created by Jack Ross on 4/21/16.
//  Copyright © 2016 Jack Ross. All rights reserved.
//

import UIKit
import Charts
import CoreBluetooth

class EKGViewController: UIViewController, BluetoothSerialDelegate {
    
    
    // MARK: Properties
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var liveHeartRate: UILabel!
    @IBOutlet weak var averageHeartRate: UILabel!
    @IBOutlet weak var barButton: UIBarButtonItem!
    
    @IBOutlet weak var BPMView: UIView!
    @IBOutlet weak var footerView: UIView!
    
    var chartScaleIndex = 0 // 0-4
    
    @IBOutlet weak var xScaleButton1: UIButton!
    @IBOutlet weak var xScaleButton2: UIButton!
    @IBOutlet weak var xScaleButton3: UIButton!
    @IBOutlet weak var xScaleButton4: UIButton!
    @IBOutlet weak var xScaleButton5: UIButton!
    @IBOutlet weak var sliderLeadingEdgeConstraint: NSLayoutConstraint!
    
    var ekgVoltages: [Double] = []
    static let bucketSize = 1;
    static let sampleRate = 1.0/120
    static let deltaX = EKGViewController.sampleRate * Double(EKGViewController.bucketSize)
    var bufferArrayBytes = [UInt8](count: 100, repeatedValue: 0)
    
    var peakDetection: PeakDetection?
    
    // MARK: Set up View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init serial bluetooth
        serial = BluetoothSerial(delegate: self)
        peakDetection = PeakDetection(deltaX: EKGViewController.deltaX, binSizeSeconds: nil)
 
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(EKGViewController.reloadView), name: "reloadStartViewController", object: nil)
        
        // instantiate 30 seconds of flat line
        print(EKGViewController.deltaX)
        let maxSamples = Int(30 / EKGViewController.deltaX)
        ekgVoltages = [Double](count: maxSamples, repeatedValue: 0.0)
        loadDummyData()
        
        self.title = "EKG Graph"
        liveHeartRate.text = "--"
        averageHeartRate.text = "--"
        configureNav()
        reloadView()
        
        // set chart graphics and default to 5 seconds
        configureChart()
        addLimitLine()
        
        chartScaleIndex = 1;
        setChartScale(5)
        
        NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(EKGViewController.updateGraph), userInfo: nil, repeats: true)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    func configureNav() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .Plain, target: self, action: #selector(reset))
    }
    
    func reloadView() {
        // in case we're the visible view again
        serial.delegate = self
        
        if serial.isReady {
            barButton.title = "Disconnect"
            barButton.tintColor = UIColor.redColor()
            barButton.enabled = true
        } else if serial.state == .PoweredOn {
            barButton.title = "Connect"
            barButton.tintColor = view.tintColor
            barButton.enabled = true
        } else {
            barButton.title = "Connect"
            barButton.tintColor = view.tintColor
            barButton.enabled = false
        }
    }
    
    func reset() {
        print("reset")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Configure Chart
    
    func loadDummyData () {
        for i in 0..<Constants.EKGTimes.count {
            ekgVoltages.removeFirst()
            ekgVoltages.append(Constants.EKGValues[i])
            peakDetection?.addDataPoint(Constants.EKGValues[i])
        }
    }
    
    func setChartData(values: [Double]) {
        lineChartView.noDataText = "You need to provide data for the chart."
        
        
        var dataEntries: [ChartDataEntry] = []
        var dataPoints: [Int] = []
        
        for i in 0..<values.count {
            let dataEntry = ChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
            dataPoints.append(i)
        }
        
        let chartDataSet = LineChartDataSet(yVals: dataEntries, label: "mV")
        chartDataSet.circleRadius = 1;
        let chartData = LineChartData(xVals: dataPoints, dataSet: chartDataSet)
        lineChartView.data = chartData
    }
    
    func updateGraph(){
        switch chartScaleIndex {
        case 0:
            setChartScale(1)
        case 1:
            setChartScale(5)
        case 2:
            setChartScale(10)
        case 3:
            setChartScale(20)
        case 4:
            setChartScale(30)
        default:
            setChartScale(5)
        }
    }
    
    func addChartDataPoint(value: Double) {
        
        ekgVoltages.removeFirst()
        ekgVoltages.append(value)
        peakDetection?.addDataPoint(value)
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
    
    
    // MARK: Set Chart Scale
    
    func setChartScale(seconds: Int) {
        let numSamples = Int(Double(seconds)/EKGViewController.deltaX)
        let lastIndex = ekgVoltages.endIndex - 1;
        var adjustedStart = lastIndex - numSamples;
        if adjustedStart < 0 { adjustedStart = 0 }
        
        // fill data using most recent data (at end of array)
        var data = [Double]()
        for i in adjustedStart...lastIndex {
            data.append(ekgVoltages[i])
        }
        setChartData(data)
        updateScaleSlider()
    }
    
    func updateScaleSlider() {
        let buttonWidth = xScaleButton1.frame.width
        let xOffset = buttonWidth * CGFloat(chartScaleIndex)
            
        sliderLeadingEdgeConstraint.constant = xOffset
    }
    
    
    var bucket = [Int]()
    func parseByteArray(bytes: [UInt8]) {
        for i in 0..<bytes.count {
            bufferArrayBytes.removeFirst()
            bufferArrayBytes.append(bytes[i])
            
            if bufferArrayBytes.first == 255 {
                let bit0 = Int(bufferArrayBytes[1]) << 12
                let bit1 = Int(bufferArrayBytes[2]) << 8
                let bit2 = Int(bufferArrayBytes[3]) << 4
                let bit3 = Int(bufferArrayBytes[4])
                
                let value = bit0 ^ bit1 ^ bit2 ^ bit3
                bucket.append(value)
                addChartDataPoint(Double(value))
                
                // if ten values, average and add voltage
//                if bucket.count == EKGViewController.bucketSize {
//                    let averageVoltage = bucket.reduce(0, combine: +) / bucket.count
//                    addChartDataPoint(Double(averageVoltage))
//                    bucket.removeAll(keepCapacity: false)
//                }
            }
        }
        
    }
    
    //MARK: BluetoothSerialDelegate
    
    func serialDidReceiveBytes(bytes: [UInt8]) {
        parseByteArray(bytes)
    }
    
    func serialDidDisconnect(peripheral: CBPeripheral, error: NSError?) {
        reloadView()
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Disconnected"
        hud.hide(true, afterDelay: 1.0)
    }
    
    func serialDidChangeState(newState: CBCentralManagerState) {
        print("did change state")
        reloadView()
        if newState != .PoweredOn {
            let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
            hud.mode = MBProgressHUDMode.Text
            hud.labelText = "Bluetooth turned off"
            hud.hide(true, afterDelay: 1.0)
        }
    }
    
    func serialDidConnect(peripheral: CBPeripheral) {
        print("serial did connect")
    }
    
    func serialIsReady(peripheral: CBPeripheral) {
        print("connected")
    }
    
    //MARK: IBActions
    
    @IBAction func barButtonPressed(sender: AnyObject) {
        if serial.connectedPeripheral == nil {
            performSegueWithIdentifier("ShowScanner", sender: self)
        } else {
            serial.disconnect()
            reloadView()
        }
    }
    
    @IBAction func setXScale1Sec(sender: AnyObject) {
        chartScaleIndex = 0
        setChartScale(1)
    }
    
    @IBAction func setXScale5Sec(sender: AnyObject) {
        chartScaleIndex = 1
        setChartScale(5)
    }
    
    @IBAction func setXScale10Sec(sender: AnyObject) {
        chartScaleIndex = 2
        setChartScale(10)
    }
    
    @IBAction func setXScale20Sec(sender: AnyObject) {
        chartScaleIndex = 3
        setChartScale(20)
    }
    
    @IBAction func setXScale30Sec(sender: AnyObject) {
        chartScaleIndex = 4
        setChartScale(30)
    }
    
    // MARK: Handle Orientation
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        var text=""
        switch UIDevice.currentDevice().orientation{
        case .Portrait, .PortraitUpsideDown:
            text="Portrait"
            BPMView.hidden = false
            footerView.hidden = false
        case .LandscapeLeft, .LandscapeRight:
            text="Landscape"
            BPMView.hidden = true
            footerView.hidden = true
        default:
            BPMView.hidden = false
            footerView.hidden = false
        }
        print("You have moved: \(text)")
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        updateScaleSlider()
    }

}

