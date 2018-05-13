//
//  CountryPicker.swift
//  Missito
//
//  Created by George Poenaru on 26/05/16.
//  Copyright © 2016 Missito GmbH. All rights reserved.
//

import UIKit
import FontAwesome_swift

class CountryPickerController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var completion: ((_ country: Country?) -> ())?
    var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWYZ".characters.map { String($0) }
    
    var selectedCountry: Country? = nil
    
    var datasource = Utils.countriesAsDataSource
    let countries = Utils.countriesAsDataSource
    let checkmark = UIImage(named: "chat_sent")
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tintColor = UIColor.missitoBlue
        tableView.sectionIndexBackgroundColor = UIColor.whiteWithAlpha0x44
        searchBar.delegate = self
        searchBar.tintColor = UIColor.missitoBlue
        
        //Hide Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CountryPickerController.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func hideKeyboard() {
        searchBar.endEditing(true)
    }
    
    func startSearch(_ searchText: String) {
        filterBy(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text, !searchText.isEmpty {
            filterBy(searchText)
        }
        hideKeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            filterBy(searchText)
        } else {
            datasource = Utils.countriesAsDataSource
            tableView.reloadData()
        }
    }

    func filterBy(_ term: String) {
        let datasource = self.countries.map { (section) -> [Country] in
            return section.filter({ country -> Bool in
                return country.countryName.lowercased().hasPrefix(term.lowercased()) || ("+" + country.dialCode).contains(term)
            })
        }
        
        self.datasource = datasource.filter({!$0.isEmpty})
        self.tableView.reloadData()
        // Scroll to top if tableview is not empty
        if !self.datasource.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = indexOf(selectedCountry) {
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return datasource.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "header_cell") as! CustomHeaderCell
        headerCell.sectionName.text = datasource[section][0].countryName.substring(to: 1)
        return headerCell.contentView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource[section].count
    }
    
    func tableView( _ tableView : UITableView, titleForHeaderInSection section: Int)-> String? {
        return datasource[section].isEmpty ? nil : alphabet[section]
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return alphabet
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CountryCell
        let country = datasource[indexPath.section][indexPath.row]
        cell.prepare(country, country.countryCode == selectedCountry?.countryCode)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // animated to true makes the grey fade out, set to false for it to immediately go away

        let country = datasource[indexPath.section][indexPath.row]
        selectedCountry = country
        completion?(country)
        navigationController?.popViewController(animated: true)
    }
    
    func indexOf(_ country: Country?) -> IndexPath? {
        guard let country = country,
              let character = country.countryName.characters.first,
              let sectionIndex = alphabet.index(of: String(character)) else {
            return nil
        }
        
        let countries = datasource[sectionIndex]
        for i in 0...countries.count-1  {
            if country.countryCode == countries[i].countryCode {
                return IndexPath.init(row: i, section: sectionIndex)
            }
        }
        return nil
    }
}

extension CountryPickerController {
    @objc func keyboardWillShow(_ notification:Notification)
    {
        let userInfo = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardFrame = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        tableViewBottomConstraint.constant = keyboardRectangle.height
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        tableViewBottomConstraint.constant = 0
    }
}
