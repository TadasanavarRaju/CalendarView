/*
 * CalendarView+DataSource.swift
 * Created by Michael Michailidis on 24/10/2017.
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
import SDWebImage

extension CalendarView: UICollectionViewDataSource {
    
    internal func resetDateCaches() {
        _startDateCache = nil
        _endDateCache = nil
        
        _firstDayCache = nil
        _lastDayCache = nil
        
        _cachedMonthInfoForSection.removeAll()
    }
    
    internal var startDateCache: Date {
        if _startDateCache == nil {
            _startDateCache = dataSource?.startDate()
        }
        
        return _startDateCache ?? Date()
    }
    
    internal var endDateCache: Date {
        if _endDateCache == nil {
            _endDateCache = dataSource?.endDate()
        }
        
        return _endDateCache ?? Date()
    }
    
    internal var firstDayCache: Date {
        if _firstDayCache == nil {
            let startDateComponents = self.calendar.dateComponents([.era, .year, .month, .day], from: startDateCache)
            
            var firstDayOfStartMonthComponents = startDateComponents
            firstDayOfStartMonthComponents.day = 1
            
            let firstDayOfStartMonthDate = self.calendar.date(from: firstDayOfStartMonthComponents)!
            
            _firstDayCache = firstDayOfStartMonthDate
        }
        
        return _firstDayCache ?? Date()
    }
    
    internal var lastDayCache: Date {
        if _lastDayCache == nil {
            var lastDayOfEndMonthComponents = self.calendar.dateComponents([.era, .year, .month], from: self.endDateCache)
            let range = self.calendar.range(of: .day, in: .month, for: self.endDateCache)!
            lastDayOfEndMonthComponents.day = range.count
            
            _lastDayCache = self.calendar.date(from: lastDayOfEndMonthComponents)!
        }
        
        return _lastDayCache ?? Date()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        guard self.dataSource != nil else { return 0 }
        
        if dataSource?.startDate() != _startDateCache ||
            dataSource?.endDate() != _endDateCache
        {
            self.resetDateCaches()
        }
        
        guard self.startDateCache <= self.endDateCache else { fatalError("Start date cannot be later than end date.") }

        let startDateComponents = self.calendar.dateComponents([.era, .year, .month, .day], from: startDateCache)
        let endDateComponents = self.calendar.dateComponents([.era, .year, .month, .day], from: endDateCache)
        
        let local = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())!
        let today = Date().convertToTimeZone(from: self.calendar.timeZone, to: local)
        if (self.firstDayCache ... self.lastDayCache).contains(today) {
            
            let distanceFromTodayComponents = self.calendar.dateComponents([.month, .day], from: self.firstDayCache, to: today)
            
            self.todayIndexPath = IndexPath(item: distanceFromTodayComponents.day!, section: distanceFromTodayComponents.month!)
        }
        
        // how many months should the whole calendar display?
        let numberOfMonths = self.calendar.dateComponents([.month], from: firstDayCache, to: lastDayCache).month!
        
        // subtract one to include the day
        self.startIndexPath = IndexPath(item: startDateComponents.day! - 1, section: 0)
        self.endIndexPath = IndexPath(item: endDateComponents.day! - 1, section: numberOfMonths)
        
        // if we are for example on the same month and the difference is 0 we still need 1 to display it
        return numberOfMonths + 1
    }
    
    public func getCachedSectionInfo(_ section: Int) -> (firstDay: Int, daysTotal: Int)? {
        var result = _cachedMonthInfoForSection[section]
        
        if result != nil
        {
            return result!
        }
        
        var monthOffsetComponents = DateComponents()
        monthOffsetComponents.month = section
        
        let date = self.calendar.date(byAdding: monthOffsetComponents, to: firstDayCache)
        
        var firstWeekdayOfMonthIndex    = date == nil ? 0 : self.calendar.component(.weekday, from: date!)
        firstWeekdayOfMonthIndex       -= style.firstWeekday == .monday ? 1 : 0
        firstWeekdayOfMonthIndex        = (firstWeekdayOfMonthIndex + 6) % 7 // push it modularly to map it in the range 0 to 6
        
        guard let rangeOfDaysInMonth = date == nil ? nil : self.calendar.range(of: .day, in: .month, for: date!)
            else { return nil }
        
        result = (firstDay: firstWeekdayOfMonthIndex, daysTotal: rangeOfDaysInMonth.count)
        
        _cachedMonthInfoForSection[section] = result
        
        return result
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42 // rows:7 x cols:6
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dayCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! CalendarDayCell
        
        dayCell.style = style
        dayCell.clearStyles()
        
        dayCell.transform = _isRtl
        ? CGAffineTransform(scaleX: -1.0, y: 1.0)
        : CGAffineTransform.identity
        
        guard let (firstDayIndex, numberOfDaysTotal) = self.getCachedSectionInfo(indexPath.section) else { return dayCell }
        
        let lastDayIndex = firstDayIndex + numberOfDaysTotal
        
        let cellOutOfRange = { (indexPath: IndexPath) -> Bool in
            if self.startIndexPath.section == indexPath.section { // is 0
                return self.startIndexPath.item + firstDayIndex > indexPath.item
            }
            if self.endIndexPath.section == indexPath.section {
                return self.endIndexPath.item + firstDayIndex < indexPath.item
            }
            return false
        }
        
        let isInRange = (firstDayIndex..<lastDayIndex).contains(indexPath.item)
        let isAdjacent = !isInRange && style.showAdjacentDays && (
            indexPath.item < firstDayIndex || indexPath.item >= lastDayIndex
        )
        
        // the index of this cell is within the range of first and the last day of the month
        if isInRange || isAdjacent {
            dayCell.isHidden = false
            
            if isAdjacent {
                if indexPath.item < firstDayIndex {
                    if let prevInfo = self.getCachedSectionInfo(indexPath.section - 1) {
                        dayCell.day = prevInfo.daysTotal - firstDayIndex + indexPath.item
                    }
                    else {
                        dayCell.isHidden = true
                    }
                }
                else {
                    dayCell.day = indexPath.item - lastDayIndex + 1
                }
            }
            else {
                // ex. if the first is wednesday (index of 3), subtract 2 to show it as 1
                dayCell.day = (indexPath.item - firstDayIndex) + 1
            }
            
            dayCell.isAdjacent = isAdjacent
            dayCell.isOutOfRange = cellOutOfRange(indexPath)
            
        } else {
            dayCell.isHidden = true
            dayCell.textLabel.text = ""
            
        }
        
        // hack: send once at the beginning
        if indexPath.section == 0 && indexPath.item == 0 {
            self.scrollViewDidEndDecelerating(collectionView)
        }
        
        guard !dayCell.isOutOfRange else { return dayCell }
        
        // if is in range continue with additional styling
        
        if let idx = self.todayIndexPath {
            dayCell.isToday = (idx.section == indexPath.section && idx.item + firstDayIndex == indexPath.item)
        }
        
        dayCell.isSelected = selectedIndexPaths.contains(indexPath)
        if selectedIndexPaths.contains(indexPath) {
            //            dayCell.backgroundColor = #colorLiteral(red: 1, green: 0.4189037681, blue: 0.3933071196, alpha: 1)
            dayCell.layer.borderColor = #colorLiteral(red: 1, green: 0.4189037681, blue: 0.3933071196, alpha: 1)
            dayCell.layer.borderWidth = style.cellSelectedBorderWidth
            dayCell.backgroundColor = style.cellSelectedColor
            
        } else {
            dayCell.layer.borderColor = UIColor.clear.cgColor
            dayCell.layer.borderWidth = 0
            dayCell.backgroundColor = UIColor.white
        }
        
        if self.marksWeekends {
            let we = indexPath.item % 7
            let weekDayOption = style.firstWeekday == .sunday ? 0 : 5
            dayCell.isWeekend = we == weekDayOption || we == 6
        }
        
        dayCell.eventsCount = self.eventsByIndexPath[indexPath]?.count ?? 0
        if dayCell.eventsCount > 1 {
            dayCell.eventCount.isHidden = false
            dayCell.eventCount.layer.masksToBounds = true
            dayCell.eventCount.layer.cornerRadius = dayCell.eventCount.bounds.width / 2
            dayCell.eventCount.text = "\(dayCell.eventsCount)"
        }else{
            dayCell.eventCount.isHidden = true
        }
        
        let eventsForDay = self.eventsByIndexPath[indexPath] ?? []
        let infoEvents = eventsForDay.filter { !$0.eventDate.isEmpty }
        dayCell.eventInfoView.isHidden = infoEvents.isEmpty
        dayCell.dotsView.isHidden = infoEvents.count == eventsForDay.count
        if eventsForDay.count > 0 {
            let event = eventsForDay[0]
            if event.eventDate.isEmpty {
                let arr = event.title.components(separatedBy: ",")
                let entityTypeId = arr[2]
                if let url: URL = URL(string: event.imageUrl) {
                    dayCell.dotsView.sd_setImage(with: url, placeholderImage: nil, options: .refreshCached)
                    dayCell.dotsView.contentMode = .scaleAspectFill
                } else {
                    if entityTypeId == "1"{
                        let placeholderImage = self.textToImage(drawText: arr[4].uppercased() as NSString)
                        dayCell.dotsView.image = placeholderImage
                    }else if entityTypeId == "2"{
                        dayCell.dotsView.image = UIImage(named: "org_icon-1")
                    }
                }
            }
        }
        
        if eventsForDay.count > 1 {
            let event = eventsForDay[1]
            if event.eventDate.isEmpty {
                let arr = event.title.components(separatedBy: ",")
                let entityTypeId = arr[2]
                if let url: URL = URL(string: event.imageUrl) {
                    dayCell.dots1View.sd_setImage(with: url, placeholderImage: nil, options: .refreshCached)
                    dayCell.dots1View.contentMode = .scaleAspectFill
                } else {
                    if entityTypeId == "1"{
                        dayCell.dots1View.image = UIImage(named: "chronogram_logo_only")
                    }else if entityTypeId == "2"{
                        dayCell.dots1View.image = UIImage(named: "org_icon-1")
                    }
                }
            }
        }
        
        
        
        //            let imageUrl:NSURL = NSURL(string: "https://chronogram.us/app/api/profile/documents/1.jpg")!
        
        dayCell.showEventDot = self.multipleSelectionEnable
        
        return dayCell
    }
    
    func textToImage(drawText text: NSString) -> UIImage? {
        //draw image first
        let background = UIImage(named: "placeholder_background")
        UIGraphicsBeginImageContext(background!.size)
        background!.draw(in: CGRect(x: 0, y: 0, width: background!.size.width, height: background!.size.height))
        
        //text attributes
        let font = UIFont(name: "Helvetica-Bold", size: 22)!
        let text_style = NSMutableParagraphStyle()
        text_style.alignment = NSTextAlignment.center
        let text_color = UIColor.darkGray
        let attributes = [NSAttributedString.Key.font:font, NSAttributedString.Key.paragraphStyle:text_style, NSAttributedString.Key.foregroundColor:text_color]

        //vertically center (depending on font)
        let text_h = font.lineHeight
        let text_y = (background!.size.height-text_h)/2
        let text_rect = CGRect(x: 0, y: text_y, width: background!.size.width, height: text_h)
        text.draw(in: text_rect.integral, withAttributes: attributes)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
