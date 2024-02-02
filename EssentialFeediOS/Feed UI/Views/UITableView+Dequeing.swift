//
//  UITableView+Dequeing.swift
//  EssentialFeediOS
//
//  Created by Omar Altali on 02/02/2024.
//

import UIKit

extension UITableView {
    func dequeueReusableCell<T: UITableViewCell>() -> T {
        let identifier = String(describing: T.self)
        return dequeueReusableCell(withIdentifier: identifier) as! T
    }
}
