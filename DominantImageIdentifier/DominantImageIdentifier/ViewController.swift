//
//  ViewController.swift
//  DominantImageIdentifier
//
//  Created by anurag ojha on 28/04/19.
//  Copyright © 2019 anuragojha. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,PinterestLayoutDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingText: UILabel!
    
    @IBOutlet weak var searchUnsplash: UITextField!
    @IBOutlet weak var feedCollectionView: UICollectionView!
    var selectedIndex:Int?
    var images: [UnsplashImage]?
    var fullresolutions = [String]()
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("count: \(images?.count ?? 0)")
        return images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        if let image = images?[indexPath.item]{
            DispatchQueue.main.async {
                cell.imageThumb.image = image.thumbImage
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItem Called and Index:",indexPath.item)
        self.selectedIndex = indexPath.item
        DispatchQueue.main.async {
            self.performSegue(withIdentifier:"loadImage", sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        print("\(#function) called")
        guard let height = images?[indexPath.item].thumbImage.size.height else{
            return 0
        }
        print("height of image: \(height) at index \(indexPath.item)")
        return height
    }
    
    override func viewDidLoad() {
        self.activityIndicator.isHidden = true
        self.loadingText.isHidden = true
        super.viewDidLoad()
        if let layout = feedCollectionView?.collectionViewLayout as? PinterestLayout {
            print("")
            layout.delegate = self
        }
        else{
            print("Inside Laytout")
        }

        print("ViewDidLoad")
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("\(#function) called")
    }
    
    @IBAction func SearchUnsplash(_ sender: Any) {
        print("called")
        guard let search = self.searchUnsplash?.text?.trimmingCharacters(in:.whitespaces) else{
            print("else called")
            self.searchUnsplash.placeholder = "something needed"
            return
        }
        activityIndicator.isHidden = false
        self.loadingText.isHidden = false
        activityIndicator.startAnimating()
        self.images = [UnsplashImage]()
        let group = DispatchGroup()
        NetworkRequest.getImages(search: search, completionHandler:{ (responsejson) in
            DispatchQueue.global(qos: .background).async(group: group) {
            group.enter()
                if let response = responsejson as? Response{
                for result in response.results!{
                    let image = UnsplashImage()
                    let imageUrl = URL(string: result.urls!.thumb!)
                    do{
                        let data = try Data(contentsOf: imageUrl!)
                        image.thumbImage = UIImage(data: data)!
                        print("ThumbImage size: \(image.thumbImage.size.height)")
                    }catch{
                        print(error.localizedDescription)
                    }
                    self.images?.append(image)
                }
                }
                else{
                    print("unable to Parse response")
                }
            group.leave()
            }
            group.notify(queue: .main) {
                print("called")
                self.feedCollectionView.reloadData()
                self.activityIndicator.stopAnimating()
                self.loadingText.isHidden = true
                self.activityIndicator.isHidden = true
            }
            
        })
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let imageVc = segue.destination as? SelectedImage else {
            return
        }
        imageVc.image = self.images![self.selectedIndex!]
        
    }
}
