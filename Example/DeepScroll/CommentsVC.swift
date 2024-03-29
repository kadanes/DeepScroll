//
//  CommentsVC.swift
//  DeepScroll_Example
//
//  Created by Michael on 11/17/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class CommentsVC: UITableViewController {
    
    private var posts: [Post]?
    private var downloadedImages: [String: UIImage] = [:]

    // Initializer that accepts an array of posts.
    init(posts: [Post]) {
        self.posts = posts
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // If iOS 13 is available, configure dark mode colors.
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(red:0.13, green:0.48, blue:0.93, alpha:1.00)]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red:0.13, green:0.48, blue:0.93, alpha:1.00)]
            navBarAppearance.backgroundColor = .white
            navigationController?.navigationBar.standardAppearance = navBarAppearance
            navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        }
        title = "Comments"
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.separatorStyle = .none
        self.tableView.register(CommentCell.self, forCellReuseIdentifier: "commentcell")
    }

    // Sets the number of sections in the table view.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Sets the number of rows in the table view.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts!.count
    }

    // Configures the cell inside of each row.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "commentcell", for: indexPath) as? CommentCell {
            cell.selectionStyle = .none
            cell.configureCell(post: posts![indexPath.row])
            setAvatar(profileUrl: posts![indexPath.row].profileUrl, avatar: cell.avatar)
            return cell
        }
        return CommentCell()
    }
    
    // Function for setting image of avatar.
    func setAvatar(profileUrl: String, avatar: UIImageView) {
        if downloadedImages[profileUrl] != nil {
            avatar.image = self.downloadedImages[profileUrl]
        } else {
            self.fetchProfileImage(from: profileUrl) { (image) in
                guard let image = image else { return }
                self.downloadedImages[profileUrl] = image
                DispatchQueue.main.async {
                    avatar.image = image
                }
            }
        }
    }
    
    // Function for retrieving image data from URL.
    func fetchProfileImage(from profileLink: String, completion: @escaping (UIImage?)->()) {
        guard let url =  URL(string: profileLink) else {
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, error == nil else { return }
            completion(UIImage(data: data))
        }.resume()
    }
}
