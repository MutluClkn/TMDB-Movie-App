//
//  SearchViewController.swift
//  TMBD Movie App
//
//  Created by Mutlu Çalkan on 7.12.2022.
//

//MARK: - Frameworks
import UIKit
import Kingfisher

//MARK: - SearchViewController
class SearchViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchTableView: UITableView!
    
    //MARK: - Objects
    private var movieArray : [Movie]?
    private var selectedMovie : Movie?
    private var genreData : [Genre]? = [Genre]()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTableView.dataSource = self
        searchTableView.delegate = self
        searchBar.delegate = self
        fetchDiscoverMovies()
        fetchGenreData()
        //closeKeyboard()
    }
    
    //MARK: - Methods
    //Fetch Discovered Movie
    private func fetchDiscoverMovies(){
        MovieManager.shared.performRequest(type: MovieData.self, query: "", externalID: "", movieID: 0, movieIDSelection: .none, movieURL: .discover) { results in
            DispatchQueue.main.async { [weak self] in
                switch results{
                case.success(let movie):
                    self?.movieArray = movie.results
                case .failure(let error):
                    print(error.localizedDescription)
                }
                self?.searchTableView.reloadData()
            }
        }
    }
    //Fetch Genre Data
    private func fetchGenreData(){
        MovieManager.shared.performRequest(type: GenreData.self, query: "", externalID: "", movieID: 0, movieIDSelection: .none, movieURL: .none) { results in
            switch results{
            case.success(let genres):
                self.genreData = genres.genres
            case.failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    //Prepare For Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.searchToDetail {
            let destinationVC = segue.destination as! DetailViewController
            destinationVC.configureFromSearchVC(with: selectedMovie, and: self.genreData)
        }
    }
}

//MARK: - TableViewDataSource
extension SearchViewController: UITableViewDataSource{
    //MARK: - Number of Rows in Section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let numberOfRows = self.movieArray?.count else { return 0}
        return numberOfRows
    }
    //MARK: - Cell For Row at
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = searchTableView.dequeueReusableCell(withIdentifier: TableViewCells.searchTableViewCell, for: indexPath) as? SearchTableViewCell else {
            return UITableViewCell()
        }
        
        let movie = self.movieArray?[indexPath.row]
        cell.movieTitle.text = movie?.title
        
        if let posterPath = movie?.poster_path{
            let downloadPosterImage = URL(string: "\(MovieConstants.baseImageURL)\(posterPath)")
            cell.posterImage.kf.setImage(with: downloadPosterImage)
        }
        
        if let voteAverage = movie?.vote_average, let voteCount = movie?.vote_count {
            cell.scoreLabel.text = String(format:"%.1f", voteAverage) + " (\(String(voteCount)))"
        }
        
        
        return cell
    }
}

//MARK: - TableViewDelegate
extension SearchViewController: UITableViewDelegate {
    //MARK: - Height For Row at
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TableViewConstants.SearchAndWatchlist.heightForRowAt
    }
    //MARK: - Did Select Row at
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.selectedMovie = self.movieArray?[indexPath.row].self
        self.performSegue(withIdentifier: Segues.searchToDetail, sender: nil)
    }
}

//MARK: - SearchBarDelegate
extension SearchViewController: UISearchBarDelegate{
    //MARK: - Text Did Change
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText != "" {
            let query = searchText
            MovieManager.shared.performRequest(type: MovieData.self, query: query, externalID: "", movieID: 0, movieIDSelection: .none, movieURL: .none) { results in
                DispatchQueue.main.async { [weak self] in
                    switch results{
                    case.success(let movie):
                        self?.movieArray = movie.results
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    self?.searchTableView.reloadData()
                }
            }
        }
        else {
            self.fetchDiscoverMovies()
        }
    }
    //MARK: - SearchBar Cancel Button Clicked
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        self.fetchDiscoverMovies()
        self.view.endEditing(true)
    }
}
