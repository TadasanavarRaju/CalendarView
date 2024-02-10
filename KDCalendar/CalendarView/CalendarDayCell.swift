/*
 * CalendarDayCell.swift
 * Created by Michael Michailidis on 02/04/2015.
 * http://blog.karmadust.com/
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

import UIKit

open class CalendarDayCell: UICollectionViewCell {
    
    var style: CalendarView.Style = CalendarView.Style.Default
    
    override open var description: String {
        let dayString = self.textLabel.text ?? " "
        return "<DayCell (text:\"\(dayString)\")>"
    }
    
    var eventsCount = 0 {
        
        didSet {
            self.eventDot.isHidden = (eventsCount == 0)
            self.dotsView.isHidden = (eventsCount == 0)
            self.dots1View.isHidden = (eventsCount < 2)
            
            self.setNeedsLayout()
        }
    }
    
    var showEventDot : Bool = false {
        
        didSet {
            if showEventDot {
                self.eventDot.isHidden = (eventsCount == 0)
                self.dotsView.isHidden = true
                self.dots1View.isHidden = true
            }else{
                self.eventDot.isHidden = true
            }
            
            self.setNeedsLayout()
        }
    }
    
    
    
    var day: Int? {
        set {
            guard let value = newValue else { return self.textLabel.text = nil }
            self.textLabel.text = String(value)
            if Int(self.eventsCount) > 1 {
                self.eventCount.isHidden = false
                self.eventCount.text = "\(self.eventsCount)"
            }else{
                self.eventCount.isHidden = true
            }

        }
        get {
            guard let value = self.textLabel.text else { return nil }
            return Int(value)
        }
    }
    
    func updateTextColor() {
        if isSelected {
            self.textLabel.textColor = style.cellSelectedTextColor
        }
        else if isToday {
            self.textLabel.textColor = UIColor.black
        }
        else if isOutOfRange {
            self.textLabel.textColor = UIColor.clear
        }
        else if isAdjacent {
            self.textLabel.textColor = style.cellColorAdjacent
        }
        else if isWeekend {
            self.textLabel.textColor = style.cellTextColorWeekend
        }
        else {
            self.textLabel.textColor = UIColor.black
        }
    }
    
    var isToday : Bool = false {
        didSet {
            switch isToday {
            case true:
                self.bgView.backgroundColor = style.cellColorToday
            case false:
                self.bgView.backgroundColor = style.cellColorDefault
            }
            
            updateTextColor()
        }
    }
    
    var isOutOfRange : Bool = false {
        didSet {
            updateTextColor()
        }
    }
    
    var isAdjacent : Bool = false {
        didSet {
            updateTextColor()
        }
    }
    
    var isWeekend: Bool = false {
        didSet {
            updateTextColor()
        }
    }
    
    override open var isSelected : Bool {
        didSet {
            switch isSelected {
            case true:
                self.bgView.layer.borderColor = style.cellSelectedBorderColor.cgColor
                self.bgView.layer.borderWidth = style.cellSelectedBorderWidth
                self.bgView.backgroundColor = style.cellSelectedColor
            case false:
                self.bgView.layer.borderColor = style.cellBorderColor.cgColor
                self.bgView.layer.borderWidth = style.cellBorderWidth
                if self.isToday {
                    self.bgView.backgroundColor = style.cellColorToday
                } else {
                    self.bgView.backgroundColor = style.cellColorDefault
                }
            }
            
            updateTextColor()
        }
    }
    
    // MARK: - Public methods
    public func clearStyles() {
        self.bgView.layer.borderColor = style.cellBorderColor.cgColor
        self.bgView.layer.borderWidth = style.cellBorderWidth
        self.bgView.backgroundColor = style.cellColorDefault
        self.textLabel.textColor = UIColor.gray
        self.eventsCount = 0
    }
    
    
    let textLabel   = UILabel()
    let dotsView    = UIImageView()
    let eventDot    = UIImageView()
    let dots1View    = UIImageView()
    let eventCount = UILabel()
    let bgView      = UIView()
    let eventInfoView  = UIView()
    
    override init(frame: CGRect) {
        
        self.textLabel.textAlignment = NSTextAlignment.center

        self.eventDot.layer.masksToBounds = false
        self.eventDot.layer.cornerRadius = self.eventDot.frame.size.height/2
        self.eventDot.clipsToBounds = true
        self.eventDot.backgroundColor = #colorLiteral(red: 1, green: 0.4189037681, blue: 0.3933071196, alpha: 1)
        
//        self.dotsView.image = UIImage(named: "chronogram_logo_only")
        self.dotsView.layer.borderWidth = 0.5
        self.dotsView.layer.masksToBounds = false
        self.dotsView.layer.borderColor = UIColor.gray.cgColor
        self.dotsView.layer.cornerRadius = self.dots1View.frame.size.height/2
        self.dotsView.clipsToBounds = true
//        self.dots1View.image = UIImage(named: "chronogram_logo_only")
        self.dots1View.layer.borderWidth = 0.5
        self.dots1View.layer.masksToBounds = false
        self.dots1View.layer.borderColor = UIColor.white.cgColor
        self.dots1View.layer.cornerRadius = self.dots1View.frame.size.height/2
        self.dots1View.clipsToBounds = true
        self.textLabel.font = style.cellFont
        self.eventCount.textAlignment = .center
        self.eventCount.textColor = UIColor.white
        self.eventCount.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        self.eventCount.font = style.cellFont
        
        self.eventInfoView.layer.cornerRadius  = 5/2
        self.eventInfoView.clipsToBounds = true
        eventInfoView.backgroundColor = UIColor.lightGray
        eventInfoView.isHidden = true
        
        super.init(frame: frame)
        
        self.addSubview(self.bgView)
        self.addSubview(self.textLabel)
        self.addSubview(self.dots1View)
        self.addSubview(self.dotsView)

        self.addSubview(self.eventCount)
        self.addSubview(self.eventDot)
        self.addSubview(self.eventInfoView)
    }
    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func layoutSubviews() {
        
        super.layoutSubviews()
        
        var elementsFrame = self.bounds.insetBy(dx: 3.0, dy: 3.0)
        
        if style.cellShape.isRound { // square of
            let smallestSide = min(elementsFrame.width + 2 , elementsFrame.height)
            elementsFrame = elementsFrame.insetBy(
                dx: (elementsFrame.width - smallestSide) / 2.0,
                dy: (elementsFrame.height - smallestSide) / 2.0
            )
        }
        
        self.bgView.frame           = elementsFrame
        self.textLabel.frame        = CGRect(x: self.bounds.width / 2 - 8, y: 2, width: 16, height: 16)
        self.eventInfoView.frame    = CGRect(x: self.bounds.width / 2 - 2.5, y: 16, width: 5, height: 5)
        
        let size                            = self.bounds.width * 0.5 // always a percentage of the whole cell
        let dotsViewXaxis = self.bounds.width / 10
        
        self.eventDot.frame                 = CGRect(x: self.bounds.width * 0.4 , y: 25, width: size/2, height: size/2)
        self.dots1View.frame                 = CGRect(x: dotsViewXaxis * 1.5 , y: 20, width: size, height: size)
        self.dotsView.frame                 = CGRect(x: dotsViewXaxis * 3.5, y: 20, width: size, height: size)
        self.eventCount.frame = CGRect(x: self.bounds.width * 0.65 , y: 18, width: 12, height: 12)
        
//        self.dotsView.center                = CGPoint(x: self.textLabel.center.x, y: self.bounds.height)
        self.eventDot.layer.cornerRadius    = size * 0.25 // round it
        self.dotsView.layer.cornerRadius    = size * 0.5 // round it
        self.dots1View.layer.cornerRadius    = size * 0.5 // round it

        switch style.cellShape {
        case .square:
            self.bgView.layer.cornerRadius = 0.0
        case .round:
            self.bgView.layer.cornerRadius = 0
        case .bevel(let radius):
            self.bgView.layer.cornerRadius = radius
        }
        
        
    }
    
}


